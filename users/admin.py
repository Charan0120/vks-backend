from django.contrib import admin
from django import forms
from .models import User


class UserAdminForm(forms.ModelForm):
    password = forms.CharField(
        widget=forms.PasswordInput(),
        required=False,
        help_text="Leave blank to keep existing password, or enter a new password."
    )

    class Meta:
        model = User
        fields = ['email', 'username', 'first_name', 'last_name', 'phone', 'role', 'centre', 'is_active', 'is_staff', 'is_superuser']

    def save(self, commit=True):
        user = super().save(commit=False)
        password = self.cleaned_data.get('password')
        if password:
            user.set_password(password)
        if commit:
            user.save()
        return user


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    form = UserAdminForm
    list_display = ('email', 'first_name', 'last_name', 'role', 'centre', 'is_staff', 'is_active', 'date_joined')
    list_filter = ('role', 'centre', 'is_staff', 'is_active')
    search_fields = ('email', 'first_name', 'last_name', 'phone')
    ordering = ('-date_joined',)
    readonly_fields = ('date_joined', 'last_login')

    fieldsets = (
        ('Account Credentials', {
            'fields': ('email', 'username', 'password')
        }),
        ('Personal Information', {
            'fields': ('first_name', 'last_name', 'phone')
        }),
        ('Role & Centre Assignment', {
            'fields': ('role', 'centre')
        }),
        ('Permissions & Status', {
            'fields': ('is_active', 'is_staff', 'is_superuser')
        }),
        ('Important Dates', {
            'fields': ('date_joined', 'last_login')
        }),
    )


