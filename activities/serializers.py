from rest_framework import serializers
from .models import Activity, Project


class ProjectSerializer(serializers.ModelSerializer):
    class Meta:
        model = Project
        fields = ['id', 'title', 'description']


class ActivitySerializer(serializers.ModelSerializer):
    project = ProjectSerializer(read_only=True)
    project_id = serializers.PrimaryKeyRelatedField(
        queryset=Project.objects.all(), source='project', write_only=True, required=False, allow_null=True
    )

    class Meta:
        model = Activity
        fields = [
            'id', 'title', 'description', 'event_date', 'year',
            'location', 'impact', 'beneficiaries_count',
            'project', 'project_id', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']
