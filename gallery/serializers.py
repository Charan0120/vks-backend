from rest_framework import serializers
from .models import GalleryItem


class GalleryItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = GalleryItem
        fields = ['id', 'activity', 'file', 'video_url', 'media_type', 'album_name', 'caption', 'created_at']
        read_only_fields = ['created_at']
