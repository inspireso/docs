from datetime import datetime, timedelta

from dateutil.relativedelta import relativedelta

d1 = datetime(2024, 2, 29)
print(d1)

d2 = d1 - timedelta(days=1)
print(d2)

# 加一年
d3 = d1 - relativedelta(years=1)
print(d3)

d3 = d1 - timedelta(days=365)
print(d3)


# print(one_year_later)
# d3 = d2 + timedelta(year=1)
# print(d3)
