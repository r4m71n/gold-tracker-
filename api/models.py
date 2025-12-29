from django.db import models
from django.contrib.auth.models import User


class Currency(models.Model):
    # اطلاعات ثابت ارز (مثلاً: دلار، usd، آیکون)
    name = models.CharField(max_length=50, verbose_name="نام ارز")  # مثلا: دلار آمریکا
    code = models.CharField(max_length=20, unique=True, verbose_name="کد")  # مثلا: usd_rl (کد TGJU)
    icon = models.CharField(max_length=100, blank=True, null=True)  # لینک آیکون یا اسم فایل
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.name

class PriceLog(models.Model):
    # تاریخچه قیمت‌ها
    currency = models.ForeignKey(Currency, on_delete=models.CASCADE, related_name='prices')
    price = models.IntegerField(verbose_name="قیمت (ریال)")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']  # جدیدترین اول بیاد

class Watchlist(models.Model):
    # لیست علاقه‌مندی کاربر
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    currency = models.ForeignKey(Currency, on_delete=models.CASCADE)
    added_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'currency')  # هر کاربر یک ارز رو فقط یک بار لایک کنه
