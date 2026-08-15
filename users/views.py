from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView
from .serializers import RegisterSerializer, LoginSerializer, UserProfileSerializer


class RegisterView(APIView):
    """
    POST /api/auth/register/
    Registers a new public user. Returns JWT tokens on success.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            refresh = RefreshToken.for_user(user)
            return Response({
                'message': 'Registration successful.',
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'user': UserProfileSerializer(user).data,
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    """
    POST /api/auth/login/
    Authenticates a user and returns JWT tokens.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            refresh = RefreshToken.for_user(user)
            return Response({
                'message': 'Login successful.',
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'user': UserProfileSerializer(user).data,
            }, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LogoutView(APIView):
    """
    POST /api/auth/logout/
    Blacklists the refresh token (logs out the user).
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data['refresh']
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({'message': 'Logged out successfully.'}, status=status.HTTP_200_OK)
        except Exception:
            return Response({'error': 'Invalid token.'}, status=status.HTTP_400_BAD_REQUEST)


class ProfileView(APIView):
    """
    GET /api/auth/profile/   — View your profile
    PATCH /api/auth/profile/ — Update name, phone
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        serializer = UserProfileSerializer(request.user)
        return Response(serializer.data)

    def patch(self, request):
        serializer = UserProfileSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


from rest_framework import generics, filters
from .models import User
from .serializers import AdminUserSerializer

class IsAdminUser(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and (request.user.role == 'ADMIN' or request.user.is_superuser)

class IsStaffOrAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and (request.user.role in ['ADMIN', 'STAFF'] or request.user.is_superuser or request.user.is_staff)

class UserListView(generics.ListAPIView):
    """
    GET /api/auth/users/ — List all users (admin only).
    """
    queryset = User.objects.all()
    serializer_class = AdminUserSerializer
    permission_classes = [IsAdminUser]
    filter_backends = [filters.SearchFilter]
    search_fields = ['email', 'username', 'first_name', 'last_name', 'phone']

    def get_queryset(self):
        qs = super().get_queryset()
        role = self.request.query_params.get('role')
        if role:
            qs = qs.filter(role=role.upper())
        return qs

class UserRoleUpdateView(generics.UpdateAPIView):
    """
    PATCH /api/auth/users/<id>/role/ — Update user role (admin only).
    """
    queryset = User.objects.all()
    serializer_class = AdminUserSerializer
    permission_classes = [IsAdminUser]
    http_method_names = ['patch']

    def patch(self, request, *args, **kwargs):
        return self.partial_update(request, *args, **kwargs)


# ── OTP Verification ──────────────────────────────────────────────────────────
from .otp_service import generate_otp, send_otp_sms, save_otp, verify_otp

class SendOtpView(APIView):
    """
    POST /api/auth/send-otp/
    Sends a 6-digit OTP to the given phone number.
    Body: { "phone": "9876543210" }
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        phone = request.data.get('phone', '').strip()
        if not phone or len(phone) < 10:
            return Response({'error': 'Valid phone number required.'}, status=status.HTTP_400_BAD_REQUEST)

        otp = generate_otp()
        save_otp(phone, otp)
        success = send_otp_sms(phone, otp)

        if success:
            return Response({'message': f'OTP sent to {phone}.'}, status=status.HTTP_200_OK)
        return Response({'error': 'Failed to send OTP. Try again.'}, status=status.HTTP_503_SERVICE_UNAVAILABLE)


class VerifyOtpView(APIView):
    """
    POST /api/auth/verify-otp/
    Verifies the OTP entered by the user.
    Body: { "phone": "9876543210", "otp": "123456" }
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        phone = request.data.get('phone', '').strip()
        otp   = request.data.get('otp', '').strip()

        if not phone or not otp:
            return Response({'error': 'Phone and OTP are required.'}, status=status.HTTP_400_BAD_REQUEST)

        if verify_otp(phone, otp):
            return Response({'verified': True, 'message': 'Phone number verified!'}, status=status.HTTP_200_OK)
        return Response({'verified': False, 'error': 'Invalid or expired OTP.'}, status=status.HTTP_400_BAD_REQUEST)

