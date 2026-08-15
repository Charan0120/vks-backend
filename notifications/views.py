from rest_framework import generics, permissions
from .models import Notification
from .serializers import NotificationSerializer


class IsAdminOrStaff(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in ['ADMIN', 'STAFF']


class NotificationListCreateView(generics.ListCreateAPIView):
    """
    GET  /api/notifications/ — List notifications (public read)
    POST /api/notifications/ — Send a notification (admin/staff only)
    """
    queryset = Notification.objects.all()
    serializer_class = NotificationSerializer

    def get_permissions(self):
        if self.request.method == 'GET':
            return [permissions.AllowAny()]
        return [IsAdminOrStaff()]

    def perform_create(self, serializer):
        serializer.save(sent_by=self.request.user)
