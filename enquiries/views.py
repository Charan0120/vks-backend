from rest_framework import generics, permissions, filters
from .models import Enquiry
from .serializers import EnquirySerializer, EnquiryAdminSerializer


class IsAdminOrStaff(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and (request.user.role in ['ADMIN', 'STAFF'] or request.user.is_superuser or request.user.is_staff)


class EnquirySubmitView(generics.CreateAPIView):
    """
    POST /api/enquiries/submit/
    Submit a new enquiry. Open to any authenticated user or
    can be submitted by staff directly on behalf of a walk-in.
    """
    serializer_class = EnquirySerializer
    permission_classes = [permissions.IsAuthenticated]


class EnquiryListView(generics.ListAPIView):
    """
    GET /api/enquiries/
    List all enquiries. Admin/Staff only.
    Supports ?status=ENROLLED and ?search=name
    """
    queryset = Enquiry.objects.all()
    serializer_class = EnquiryAdminSerializer
    permission_classes = [IsAdminOrStaff]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'phone', 'email', 'location']
    ordering_fields = ['created_at', 'enquiry_date', 'status']

    def get_queryset(self):
        qs = Enquiry.objects.all()
        user = self.request.user
        
        # Staff is filtered to their assigned centre
        if user.role == 'STAFF' and user.centre != 'ALL':
            qs = qs.filter(preferred_centre=user.centre)
        # Admin can view all and filter by preferred_centre parameter
        elif user.role == 'ADMIN' or user.centre == 'ALL':
            centre_filter = self.request.query_params.get('preferred_centre')
            if centre_filter:
                qs = qs.filter(preferred_centre=centre_filter.upper())

        status = self.request.query_params.get('status')
        referred_by = self.request.query_params.get('referred_by')
        fees_type = self.request.query_params.get('fees_type')
        if status:
            qs = qs.filter(status=status.upper())
        if referred_by:
            qs = qs.filter(referred_by=referred_by.upper())
        if fees_type:
            qs = qs.filter(fees_type=fees_type.upper())
        return qs


class EnquiryDetailView(generics.RetrieveUpdateAPIView):
    """
    GET  /api/enquiries/<id>/ — View enquiry detail
    PATCH /api/enquiries/<id>/ — Update status, remarks (admin/staff)
    """
    queryset = Enquiry.objects.all()
    serializer_class = EnquiryAdminSerializer
    permission_classes = [IsAdminOrStaff]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'STAFF' and user.centre != 'ALL':
            return Enquiry.objects.filter(preferred_centre=user.centre)
        return Enquiry.objects.all()
