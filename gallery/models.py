from django.db import models
from activities.models import Activity


class GalleryItem(models.Model):
    """A photo or video in the gallery, optionally linked to an activity."""

    class MediaType(models.TextChoices):
        IMAGE = 'IMAGE', 'Image'
        VIDEO = 'VIDEO', 'Video'

    activity = models.ForeignKey(
        Activity,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='gallery_items',
    )
    file = models.FileField(upload_to='gallery/%Y/%m/', blank=True)
    video_url = models.URLField(blank=True, help_text='YouTube or external video URL (alternative to file upload)')
    media_type = models.CharField(max_length=10, choices=MediaType.choices, default=MediaType.IMAGE)
    album_name = models.CharField(max_length=150, blank=True)
    caption = models.CharField(max_length=300, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Gallery Item'
        verbose_name_plural = 'Gallery Items'

    def __str__(self):
        label = self.album_name or (self.activity.title if self.activity else 'General')
        return f"{self.media_type} — {label}"
