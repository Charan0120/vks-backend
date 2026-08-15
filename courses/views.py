from rest_framework import generics, permissions
from .models import Course
from .serializers import CourseSerializer


class IsAdminOrStaffOrReadOnly(permissions.BasePermission):
    """Allow read-only for anyone, write only for admin/staff."""
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return request.user.is_authenticated and request.user.role in ['ADMIN', 'STAFF']


class CourseListView(generics.ListCreateAPIView):
    """
    GET  /api/courses/ — List active courses for public, all courses for admin/staff.
    POST /api/courses/ — Create a new course (admin/staff only).
    """
    queryset = Course.objects.all()
    serializer_class = CourseSerializer
    permission_classes = [IsAdminOrStaffOrReadOnly]

    def get_queryset(self):
        user = self.request.user
        if user and user.is_authenticated and user.role in ['ADMIN', 'STAFF']:
            return Course.objects.all()
        return Course.objects.filter(is_active=True)


class CourseDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET    /api/courses/<id>/ — View course details.
    PUT    /api/courses/<id>/ — Complete update of a course (admin/staff only).
    PATCH  /api/courses/<id>/ — Partial update/deactivate of a course (admin/staff only).
    DELETE /api/courses/<id>/ — Delete a course (admin/staff only).
    """
    queryset = Course.objects.all()
    serializer_class = CourseSerializer
    permission_classes = [IsAdminOrStaffOrReadOnly]
