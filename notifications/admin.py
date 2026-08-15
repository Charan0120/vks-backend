from django.contrib import admin
from .models import Notification


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('title', 'topic', 'sent_by', 'created_at')
    list_filter = ('topic',)
    search_fields = ('title', 'body')
    ordering = ('-created_at',)
    readonly_fields = ('sent_by', 'created_at')
