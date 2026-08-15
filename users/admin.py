from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ('email', 'first_name', 'last_name', 'role', 'centre', 'is_active', 'date_joined')
    list_filter = ('role', 'centre', 'is_active', 'is_staff')
    search_fields = ('email', 'first_name', 'last_name', 'phone')
    ordering = ('-date_joined',)

    fieldsets = (
        ('Login Credentials', {'fields': ('email', 'password')}),
        ('Personal Information', {'fields': ('first_name', 'last_name', 'phone')}),
        ('Role & Permissions', {
            'fields': ('role', 'centre', 'is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')
        }),
        ('Activity Dates', {'fields': ('last_login', 'date_joined')}),
    )

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'username', 'first_name', 'last_name', 'phone', 'role', 'centre', 'password1', 'password2'),
        }),
    )
