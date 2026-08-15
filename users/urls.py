from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    RegisterView, LoginView, LogoutView, ProfileView,
    UserListView, UserRoleUpdateView,
    SendOtpView, VerifyOtpView,
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='auth-register'),
    path('login/', LoginView.as_view(), name='auth-login'),
    path('logout/', LogoutView.as_view(), name='auth-logout'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('profile/', ProfileView.as_view(), name='auth-profile'),

    # OTP
    path('send-otp/', SendOtpView.as_view(), name='auth-send-otp'),
    path('verify-otp/', VerifyOtpView.as_view(), name='auth-verify-otp'),

    # Admin User Management
    path('users/', UserListView.as_view(), name='admin-users-list'),
    path('users/<int:pk>/role/', UserRoleUpdateView.as_view(), name='admin-user-role-update'),
]

