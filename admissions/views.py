from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from .models import Admission, Document
from .serializers import AdmissionSerializer, AdmissionStatusUpdateSerializer, DocumentSerializer


class IsStaffOrAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in ['ADMIN', 'STAFF']


class AdmissionCreateView(generics.CreateAPIView):
    """
    POST /api/admissions/
    Submit a new admission application (requires login).
    """
    serializer_class = AdmissionSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def perform_create(self, serializer):
        serializer.save()


class MyAdmissionsView(generics.ListAPIView):
    """
    GET /api/admissions/my/
    List all admissions submitted by the current logged-in user.
    """
    serializer_class = AdmissionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Admission.objects.filter(user=self.request.user)


class AdmissionListView(generics.ListAPIView):
    """
    GET /api/admissions/all/
    List all admissions (admin/staff only).
    """
    queryset = Admission.objects.select_related('selected_course', 'user').all()
    serializer_class = AdmissionSerializer
    permission_classes = [IsStaffOrAdmin]

    def get_queryset(self):
        qs = super().get_queryset()
        status_filter = self.request.query_params.get('status')
        if status_filter:
            qs = qs.filter(status=status_filter.upper())
        return qs


class AdmissionDetailView(generics.RetrieveUpdateAPIView):
    """
    GET   /api/admissions/<id>/ — View admission details
    PATCH /api/admissions/<id>/ — Update status/remarks (admin/staff only)
    """
    queryset = Admission.objects.all()
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        if self.request.method == 'PATCH' and self.request.user.role in ['ADMIN', 'STAFF']:
            return AdmissionStatusUpdateSerializer
        return AdmissionSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role in ['ADMIN', 'STAFF']:
            return Admission.objects.all()
        return Admission.objects.filter(user=user)


class DocumentUploadView(APIView):
    """
    POST /api/admissions/<admission_id>/documents/
    Upload a document to an existing admission.
    """
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request, admission_id):
        try:
            admission = Admission.objects.get(id=admission_id, user=request.user)
        except Admission.DoesNotExist:
            return Response({'error': 'Admission not found.'}, status=status.HTTP_404_NOT_FOUND)

        file = request.FILES.get('file')
        document_type = request.data.get('document_type')

        if not file or not document_type:
            return Response({'error': 'file and document_type are required.'}, status=status.HTTP_400_BAD_REQUEST)

        doc = Document.objects.create(
            admission=admission,
            file=file,
            document_type=document_type,
            original_filename=file.name,
        )
        return Response(DocumentSerializer(doc).data, status=status.HTTP_201_CREATED)
