from rest_framework import generics, permissions, filters
from .models import Activity, Project
from .serializers import ActivitySerializer, ProjectSerializer


class IsAdminOrStaffOrReadOnly(permissions.BasePermission):
    """Allow read-only for anyone, write only for admin/staff."""
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return request.user.is_authenticated and request.user.role in ['ADMIN', 'STAFF']


class ActivityListCreateView(generics.ListCreateAPIView):
    """
    GET  /api/activities/       — List activities (public, with filters)
    POST /api/activities/       — Create activity (admin/staff only)
    """
    queryset = Activity.objects.select_related('project').all()
    serializer_class = ActivitySerializer
    permission_classes = [IsAdminOrStaffOrReadOnly]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'location', 'impact', 'description']
    ordering_fields = ['year', 'event_date', 'beneficiaries_count']

    def get_queryset(self):
        qs = super().get_queryset()
        year = self.request.query_params.get('year')
        project_id = self.request.query_params.get('project')
        location = self.request.query_params.get('location')
        if year:
            qs = qs.filter(year=year)
        if project_id:
            qs = qs.filter(project_id=project_id)
        if location:
            qs = qs.filter(location__icontains=location)
        return qs


class ActivityDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET    /api/activities/<id>/ — Get single activity (public)
    PUT    /api/activities/<id>/ — Update activity (admin/staff)
    DELETE /api/activities/<id>/ — Delete activity (admin/staff)
    """
    queryset = Activity.objects.select_related('project').all()
    serializer_class = ActivitySerializer
    permission_classes = [IsAdminOrStaffOrReadOnly]


class ProjectListView(generics.ListAPIView):
    """GET /api/activities/projects/ — List all project categories (public)."""
    queryset = Project.objects.all()
    serializer_class = ProjectSerializer
    permission_classes = [permissions.AllowAny]
