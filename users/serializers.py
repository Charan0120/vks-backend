from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from .models import User


class RegisterSerializer(serializers.ModelSerializer):
    username = serializers.CharField(required=False, allow_blank=True)
    first_name = serializers.CharField(required=False, allow_blank=True)
    last_name = serializers.CharField(required=False, allow_blank=True)
    phone = serializers.CharField(required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, min_length=6)
    password2 = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = ['id', 'email', 'username', 'first_name', 'last_name', 'phone', 'centre', 'password', 'password2']

    def validate(self, data):
        if data.get('password') != data.get('password2'):
            raise serializers.ValidationError({'password': 'Passwords do not match.'})
        return data

    def create(self, validated_data):
        validated_data.pop('password2', None)
        password = validated_data.pop('password')
        email = validated_data.get('email', '')
        username = validated_data.get('username')
        if not username:
            validated_data['username'] = email.split('@')[0] if email else 'user'
        user = User(**validated_data)
        user.set_password(password)
        user.role = User.Role.PUBLIC
        user.save()
        return user


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        user = authenticate(username=data['email'], password=data['password'])
        if not user:
            raise serializers.ValidationError('Invalid email or password.')
        if not user.is_active:
            raise serializers.ValidationError('Your account is disabled. Please contact admin.')
        data['user'] = user
        return data


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'username', 'first_name', 'last_name', 'phone', 'role', 'centre', 'date_joined']
        read_only_fields = ['id', 'email', 'role', 'centre', 'date_joined']


class TokenResponseSerializer(serializers.Serializer):
    """Helper serializer for documenting token response."""
    access = serializers.CharField()
    refresh = serializers.CharField()
    user = UserProfileSerializer()


class AdminUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'username', 'first_name', 'last_name', 'phone', 'role', 'centre', 'is_active', 'date_joined']
        read_only_fields = ['id', 'email', 'date_joined']


class AdminCreateUserSerializer(serializers.ModelSerializer):
    username = serializers.CharField(required=False, allow_blank=True)
    first_name = serializers.CharField(required=False, allow_blank=True)
    last_name = serializers.CharField(required=False, allow_blank=True)
    phone = serializers.CharField(required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = ['id', 'email', 'username', 'first_name', 'last_name', 'phone', 'role', 'centre', 'password']

    def create(self, validated_data):
        password = validated_data.pop('password')
        role = validated_data.get('role', User.Role.STAFF)
        email = validated_data.get('email', '')
        username = validated_data.get('username')
        if not username:
            username = email.split('@')[0] if email else 'user'
        validated_data['username'] = username
        user = User(**validated_data)
        user.set_password(password)
        if role in [User.Role.STAFF, User.Role.ADMIN]:
            user.is_staff = True
        user.save()
        return user


