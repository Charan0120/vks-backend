from django.db import models
from django.conf import settings


class Notification(models.Model):
    """Push notification sent to mobile app users."""

    class Topic(models.TextChoices):
        ADMISSIONS = 'ADMISSIONS', 'Admissions'
        EVENTS = 'EVENTS', 'Events'
        ANNOUNCEMENTS = 'ANNOUNCEMENTS', 'Announcements'
        COURSES = 'COURSES', 'Courses'

    title = models.CharField(max_length=200)
    body = models.TextField()
    topic = models.CharField(max_length=20, choices=Topic.choices)
    sent_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='sent_notifications',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Notification'
        verbose_name_plural = 'Notifications'

    def __str__(self):
        return f"[{self.topic}] {self.title}"
