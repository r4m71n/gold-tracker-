from django.contrib import admin
from .models import Currency, PriceLog, Watchlist

@admin.register(Currency)
class CurrencyAdmin(admin.ModelAdmin):
    list_display = ['name', 'code', 'is_active']
    list_editable = ['is_active']
    search_fields = ['name', 'code']

@admin.register(PriceLog)
class PriceLogAdmin(admin.ModelAdmin):
    list_display = ['currency', 'price', 'created_at']
    list_filter = ['currency', 'created_at']

@admin.register(Watchlist)
class WatchlistAdmin(admin.ModelAdmin):
    list_display = ['user', 'currency', 'added_at']
