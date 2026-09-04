from django.contrib import admin
from .models import Student, FeePayment, Reminder, Broadcast


class FeePaymentInline(admin.TabularInline):
    model  = FeePayment
    extra  = 0
    fields = ('amount', 'payment_date', 'payment_mode', 'receipt_note', 'recorded_by')
    readonly_fields = ('recorded_by',)


class ReminderInline(admin.TabularInline):
    model  = Reminder
    extra  = 0
    fields = ('reminder_type', 'message', 'remind_at', 'repeat_interval', 'is_sent')


@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display  = ('name', 'phone', 'status', 'centre', 'course', 'total_fee', 'added_by', 'created_at')
    list_filter   = ('status', 'centre', 'referred_by')
    search_fields = ('name', 'phone', 'email')
    inlines       = [FeePaymentInline, ReminderInline]
    readonly_fields = ('added_by', 'created_at', 'updated_at')


@admin.register(FeePayment)
class FeePaymentAdmin(admin.ModelAdmin):
    list_display  = ('student', 'amount', 'payment_date', 'payment_mode', 'recorded_by')
    list_filter   = ('payment_mode', 'payment_date')
    search_fields = ('student__name',)


@admin.register(Reminder)
class ReminderAdmin(admin.ModelAdmin):
    list_display  = ('student', 'reminder_type', 'remind_at', 'repeat_interval', 'is_sent')
    list_filter   = ('reminder_type', 'is_sent', 'repeat_interval')
    search_fields = ('student__name',)


@admin.register(Broadcast)
class BroadcastAdmin(admin.ModelAdmin):
    list_display  = ('title', 'audience', 'sent_count', 'failed_count', 'sent_by', 'sent_at')
    list_filter   = ('audience',)
    readonly_fields = ('sent_count', 'failed_count', 'sent_by', 'sent_at')
