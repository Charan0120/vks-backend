from rest_framework import serializers
from .models import Admission, Document
from courses.serializers import CourseSerializer
from courses.models import Course


class DocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Document
        fields = ['id', 'document_type', 'original_filename', 'file', 'uploaded_at']
        read_only_fields = ['original_filename', 'uploaded_at']


class AdmissionSerializer(serializers.ModelSerializer):
    documents = DocumentSerializer(many=True, read_only=True)
    selected_course_detail = CourseSerializer(source='selected_course', read_only=True)
    selected_course = serializers.PrimaryKeyRelatedField(
        queryset=Course.objects.filter(is_active=True)
    )

    class Meta:
        model = Admission
        fields = [
            'id', 'student_name', 'father_name', 'mother_name',
            'gender', 'date_of_birth', 'mobile_number', 'email', 'address',
            'qualification', 'preferred_centre', 'selected_course', 'selected_course_detail',
            'status', 'admin_remarks', 'documents', 'created_at', 'updated_at'
        ]
        read_only_fields = ['status', 'admin_remarks', 'created_at', 'updated_at']

    def create(self, validated_data):
        # Link the admission to the currently logged-in user
        user = self.context['request'].user
        admission = Admission.objects.create(user=user, **validated_data)
        return admission


class AdmissionStatusUpdateSerializer(serializers.ModelSerializer):
    """Used by admin/staff to update status and remarks only."""
    class Meta:
        model = Admission
        fields = ['status', 'admin_remarks']
