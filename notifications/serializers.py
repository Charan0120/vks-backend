from rest_framework import serializers
from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'title', 'body', 'topic', 'sent_by', 'created_at']
        read_only_fields = ['sent_by', 'created_at']
