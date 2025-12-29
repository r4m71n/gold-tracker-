from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Currency, PriceLog
from .scraper import fetch_tgju_data
from datetime import timedelta
from django.utils import timezone
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from rest_framework.authtoken.models import Token
from rest_framework.permissions import IsAuthenticated
from .models import Watchlist


class PriceListView(APIView):
    """
    API برای دریافت لیست قیمت‌ها
    خودکار هر 10 دقیقه یکبار از TGJU آپدیت می‌شه
    """

    def get(self, request):
        # 1. چک کنیم آخرین آپدیت کی بوده؟
        last_log = PriceLog.objects.order_by('-created_at').first()
        should_update = True

        if last_log:
            time_diff = timezone.now() - last_log.created_at
            if time_diff < timedelta(minutes=10):
                should_update = False
                print("[INFO] Data is fresh, skipping update")

        # 2. اگر نیاز به آپدیت بود، اسکریپر را صدا بزن
        if should_update:
            print("[UPDATE] Fetching prices from TGJU...")
            data = fetch_tgju_data()

            if data:
                for code, price in data.items():
                    # پیدا کردن یا ساخت ارز
                    currency, created = Currency.objects.get_or_create(
                        code=code,
                        defaults={
                            'name': code.upper().replace('_', ' '),
                        }
                    )

                    # ثبت قیمت جدید
                    PriceLog.objects.create(currency=currency, price=price)

                print(f"[SUCCESS] {len(data)} prices updated")
            else:
                print("[ERROR] Failed to fetch prices")

        # 3. ساخت پاسخ JSON برای Flutter
        response_data = []
        currencies = Currency.objects.filter(is_active=True)

        for curr in currencies:
            # جدیدترین قیمت
            current_log = curr.prices.first()

            if current_log:
                # محاسبه تغییر 24 ساعته
                yesterday = timezone.now() - timedelta(hours=24)
                old_log = curr.prices.filter(created_at__lte=yesterday).first()

                change_percent = 0.0
                if old_log and old_log.price > 0:
                    change_percent = ((current_log.price - old_log.price) / old_log.price) * 100

                response_data.append({
                    'id': curr.id,
                    'name': curr.name,
                    'code': curr.code,
                    'price': current_log.price,
                    'change_24h': round(change_percent, 2),
                    'last_updated': current_log.created_at.isoformat()
                })

        return Response(response_data, status=status.HTTP_200_OK)


class RegisterView(APIView):
    """
    ثبت‌نام کاربر جدید
    """

    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        email = request.data.get('email', '')

        if not username or not password:
            return Response(
                {'error': 'نام کاربری و رمز عبور الزامی است'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if User.objects.filter(username=username).exists():
            return Response(
                {'error': 'این نام کاربری قبلاً ثبت شده'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # ساخت کاربر جدید
        user = User.objects.create_user(
            username=username,
            password=password,
            email=email
        )

        # ساخت توکن برای لاگین خودکار
        token, _ = Token.objects.get_or_create(user=user)

        return Response({
            'message': 'ثبت‌نام موفق',
            'token': token.key,
            'user_id': user.id,
            'username': user.username
        }, status=status.HTTP_201_CREATED)


class LoginView(APIView):
    """
    ورود کاربر
    """

    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')

        user = authenticate(username=username, password=password)

        if user:
            token, _ = Token.objects.get_or_create(user=user)
            return Response({
                'message': 'ورود موفق',
                'token': token.key,
                'user_id': user.id,
                'username': user.username
            })
        else:
            return Response(
                {'error': 'نام کاربری یا رمز عبور اشتباه است'},
                status=status.HTTP_401_UNAUTHORIZED
            )


class WatchlistView(APIView):
    """
    مدیریت لیست علاقه‌مندی‌ها
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """لیست ارزهای علاقه‌مند"""
        watchlist = Watchlist.objects.filter(user=request.user)

        items = []
        for item in watchlist:
            curr = item.currency
            current_log = curr.prices.first()

            if current_log:
                yesterday = timezone.now() - timedelta(hours=24)
                old_log = curr.prices.filter(created_at__lte=yesterday).first()

                change_percent = 0.0
                if old_log and old_log.price > 0:
                    change_percent = ((current_log.price - old_log.price) / old_log.price) * 100

                items.append({
                    'id': curr.id,
                    'name': curr.name,
                    'code': curr.code,
                    'price': current_log.price,
                    'change_24h': round(change_percent, 2),
                    'last_updated': current_log.created_at.isoformat()
                })

        return Response(items)

    def post(self, request):
        """اضافه کردن به لیست علاقه‌مندی"""
        currency_id = request.data.get('currency_id')

        try:
            currency = Currency.objects.get(id=currency_id)
            watchlist_item, created = Watchlist.objects.get_or_create(
                user=request.user,
                currency=currency
            )

            if created:
                return Response({'message': 'به لیست علاقه‌مندی اضافه شد'})
            else:
                return Response({'message': 'قبلاً در لیست است'})

        except Currency.DoesNotExist:
            return Response(
                {'error': 'ارز پیدا نشد'},
                status=status.HTTP_404_NOT_FOUND
            )

    def delete(self, request):
        """حذف از لیست علاقه‌مندی"""
        currency_id = request.data.get('currency_id')

        deleted_count, _ = Watchlist.objects.filter(
            user=request.user,
            currency_id=currency_id
        ).delete()

        if deleted_count > 0:
            return Response({'message': 'از لیست حذف شد'})
        else:
            return Response(
                {'error': 'این ارز در لیست شما نیست'},
                status=status.HTTP_404_NOT_FOUND
            )
