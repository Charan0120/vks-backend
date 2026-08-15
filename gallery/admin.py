from django.contrib import admin
from .models import GalleryItem


@admin.register(GalleryItem)
class GalleryItemAdmin(admin.ModelAdmin):
    list_display = ('__str__', 'media_type', 'album_name', 'activity', 'created_at')
    list_filter = ('media_type', 'album_name')
    search_fields = ('album_name', 'caption', 'activity__title')
    ordering = ('-created_at',)
