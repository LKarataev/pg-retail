#### Таблица Транзакции

| **Поле**                 | **Название поля в системе** | **Формат / возможные значения** | **Описание**                                                          |
|:------------------------:|:---------------------------:|:-------------------------------:|:---------------------------------------------------------------------:|
| Идентификатор транзакции | Transaction_ID              | ---                             | Уникальное значение                                                   |
| Идентификатор карты      | Customer_Card_ID            | ---                             | ---                                                                   |
| Сумма транзакции         | Transaction_Summ            | Арабская цифра                  | Сумма транзакции в рублях (полная стоимость покупки без учета скидок) |
| Дата транзакции          | Transaction_DateTime        | дд.мм.гггг чч:мм:сс             | Дата и время совершения транзакции                                    |
| Торговая точка           | Transaction_Store_ID        | Идентификатор магазина          | Магазин, в котором была совершена транзакция                          |
