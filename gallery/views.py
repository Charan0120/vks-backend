from rest_framework import generics, permissions
from .models import GalleryItem
from .serializers import GalleryItemSerializer


class IsAdminOrStaffOrReadOnly(permissions.BasePermission):
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return request.user.is_authenticated and request.user.role in ['ADMIN', 'STAFF']


class GalleryListCreateView(generics.ListCreateAPIView):
    """
    GET  /api/gallery/ — Public gallery list (filterable by album, media_type)
    POST /api/gallery/ — Upload gallery item (admin/staff only)
    """
    queryset = GalleryItem.objects.all()
    serializer_class = GalleryItemSerializer
    permission_classes = [IsAdminOrStaffOrReadOnly]

    def get_queryset(self):
        qs = super().get_queryset()
        album = self.request.query_params.get('album')
        media_type = self.request.query_params.get('type')
        activity = self.request.query_params.get('activity')
        if album:
            qs = qs.filter(album_name__icontains=album)
        if media_type:
            qs = qs.filter(media_type=media_type.upper())
        if activity:
            qs = qs.filter(activity_id=activity)
        return qs
