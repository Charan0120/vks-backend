from rest_framework import serializers
from .models import Course, CentreContact


class CourseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Course
        fields = ['id', 'code', 'title', 'description', 'duration_months', 'is_active']


class CentreContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = CentreContact
        fields = ['id', 'centre', 'phone_number', 'email', 'address']
