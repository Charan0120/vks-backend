from rest_framework import serializers
from .models import Student, FeePayment, Reminder, Broadcast
from courses.models import Course


class FeePaymentSerializer(serializers.ModelSerializer):
    recorded_by_name = serializers.SerializerMethodField()

    class Meta:
        model  = FeePayment
        fields = [
            'id', 'student', 'amount', 'payment_date', 'payment_mode',
            'receipt_note', 'recorded_by', 'recorded_by_name', 'created_at',
        ]
        read_only_fields = ['student', 'recorded_by', 'created_at']

    def get_recorded_by_name(self, obj):
        if obj.recorded_by:
            return obj.recorded_by.get_full_name() or obj.recorded_by.email
        return None


class ReminderSerializer(serializers.ModelSerializer):
    student_name  = serializers.CharField(source='student.name', read_only=True)
    student_phone = serializers.CharField(source='student.phone', read_only=True)

    class Meta:
        model  = Reminder
        fields = [
            'id', 'student', 'student_name', 'student_phone',
            'reminder_type', 'message', 'remind_at',
            'repeat_interval', 'is_sent', 'created_by', 'created_at',
        ]
        read_only_fields = ['student', 'created_by', 'is_sent', 'created_at']


class StudentListSerializer(serializers.ModelSerializer):
    """Compact serializer for list view."""
    fee_paid      = serializers.ReadOnlyField()
    fee_remaining = serializers.ReadOnlyField()
    course_name   = serializers.CharField(source='course.title', read_only=True)

    class Meta:
        model  = Student
        fields = [
            'id', 'name', 'phone', 'email', 'status', 'centre',
            'course', 'course_name', 'total_fee', 'fee_paid', 'fee_remaining',
            'enquiry_date', 'joined_date', 'date_of_birth', 'created_at',
        ]


class StudentDetailSerializer(serializers.ModelSerializer):
    """Full serializer with nested fee payments and reminders."""
    fee_paid       = serializers.ReadOnlyField()
    fee_remaining  = serializers.ReadOnlyField()
    fee_payments   = FeePaymentSerializer(many=True, read_only=True)
    reminders      = ReminderSerializer(many=True, read_only=True)
    course_name    = serializers.CharField(source='course.title', read_only=True)
    added_by_name  = serializers.SerializerMethodField()

    class Meta:
        model  = Student
        fields = [
            'id', 'name', 'phone', 'email', 'date_of_birth', 'gender',
            'address', 'education', 'status', 'centre', 'course', 'course_name',
            'referred_by', 'enquiry_date', 'joined_date',
            'total_fee', 'fee_paid', 'fee_remaining',
            'remarks', 'added_by', 'added_by_name',
            'fee_payments', 'reminders', 'created_at', 'updated_at',
        ]
        read_only_fields = ['added_by', 'created_at', 'updated_at']

    def get_added_by_name(self, obj):
        if obj.added_by:
            return obj.added_by.get_full_name() or obj.added_by.email
        return None


class BroadcastSerializer(serializers.ModelSerializer):
    sent_by_name = serializers.SerializerMethodField()

    class Meta:
        model  = Broadcast
        fields = [
            'id', 'title', 'message', 'audience',
            'sent_count', 'failed_count', 'sent_by', 'sent_by_name', 'sent_at',
        ]
        read_only_fields = ['sent_by', 'sent_count', 'failed_count', 'sent_at']

    def get_sent_by_name(self, obj):
        if obj.sent_by:
            return obj.sent_by.get_full_name() or obj.sent_by.email
        return None
