from rest_framework import serializers
from .models import Enquiry


class EnquirySerializer(serializers.ModelSerializer):
    class Meta:
        model = Enquiry
        fields = [
            'id', 'name', 'phone', 'email', 'education', 'location',
            'preferred_centre', 'interested_course', 'fees_type', 'referred_by',
            'status', 'payment_made', 'staff_remarks',
            'enquiry_date', 'created_at',
        ]
        read_only_fields = ['id', 'created_at']


class EnquiryAdminSerializer(serializers.ModelSerializer):
    """Full serializer for admin/staff — can update status, remarks, payment."""
    class Meta:
        model = Enquiry
        fields = '__all__'
        read_only_fields = ['id', 'created_at']
