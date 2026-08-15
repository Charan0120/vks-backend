"""
OTP Service — uses Fast2SMS API to send OTPs via SMS.
Get your FREE API key at: https://www.fast2sms.com
Add FAST2SMS_API_KEY to your .env file.
"""
import random
import string
import requests
from django.core.cache import cache
from django.conf import settings

OTP_EXPIRY_SECONDS = 300  # 5 minutes


def generate_otp(length=6):
    return ''.join(random.choices(string.digits, k=length))


def send_otp_sms(phone: str, otp: str) -> bool:
    """Send OTP via Fast2SMS. Returns True if sent successfully."""
    api_key = getattr(settings, 'FAST2SMS_API_KEY', None)

    if not api_key:
        # If no API key, print to console for testing
        print(f"[OTP DEBUG] Phone: {phone} | OTP: {otp}")
        return True  # Pretend success in dev

    try:
        response = requests.post(
            'https://www.fast2sms.com/dev/bulkV2',
            headers={'authorization': api_key},
            json={
                'variables_values': otp,
                'route': 'otp',
                'numbers': phone,
            },
            timeout=10,
        )
        data = response.json()
        return data.get('return', False)
    except Exception as e:
        print(f"[OTP ERROR] {e}")
        return False


def save_otp(phone: str, otp: str):
    """Save OTP in cache (expires in 5 minutes)."""
    cache.set(f'otp_{phone}', otp, timeout=OTP_EXPIRY_SECONDS)


def verify_otp(phone: str, otp: str) -> bool:
    """Verify OTP from cache."""
    cached = cache.get(f'otp_{phone}')
    if cached and cached == otp:
        cache.delete(f'otp_{phone}')  # One-time use
        return True
    return False
