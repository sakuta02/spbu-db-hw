-- ЗАДАНИЕ 1 (транзакции):
-- Реализуйте "перевод денег" между счетами tx_accounts:
--   - списать со счета 1 сумму 200
--   - зачислить на счет 2 сумму 200
--   - если на счете 1 недостаточно средств — откатить
-- Подсказка: SELECT ... FOR UPDATE + проверка + UPDATE + COMMIT/ROLLBACK.
BEGIN;

SELECT *
FROM tx_accounts
WHERE account_id IN (1, 2)
FOR UPDATE;

DO
$$
DECLARE
    v_balance NUMERIC(12,2);
BEGIN
    SELECT balance
    INTO v_balance
    FROM tx_accounts
    WHERE account_id = 1;

    IF v_balance >= 200 THEN
        UPDATE tx_accounts
        SET balance = balance - 200,
            updated_at = now()
        WHERE account_id = 1;

        UPDATE tx_accounts
        SET balance = balance + 200,
            updated_at = now()
        WHERE account_id = 2;
    ELSE
        RAISE EXCEPTION 'Недостаточно средств на счете 1';
    END IF;
END
$$;

COMMIT;

SELECT * FROM tx_accounts ORDER BY account_id;

-- ЗАДАНИЕ 2 (savepoint):
-- В одной транзакции:
--   - обновить Alice (+10)
--   - SAVEPOINT
--   - сделать действие, которое нарушит CHECK
--   - откатиться к SAVEPOINT и завершить COMMIT.
BEGIN;
    UPDATE tx_accounts
    SET balance = balance + 10,
        updated_at = now()
    WHERE account_id = 1;

    SAVEPOINT sp_after_alice;

    DO
    $$
    BEGIN
        UPDATE tx_accounts
        SET balance = balance - 100000,
            updated_at = now()
        WHERE account_id = 2;
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'Нарушение CHECK, откатываемся к SAVEPOINT';
    END
    $$;

ROLLBACK TO SAVEPOINT sp_after_alice;

COMMIT;

SELECT * FROM tx_accounts ORDER BY account_id;

-- ЗАДАНИЕ 3 (изоляция):
-- В 2 консолях сравните READ COMMITTED и REPEATABLE READ на tx_demo и сформулируйте вывод.
-- Вывод:
-- 1) В READ COMMITTED второй SELECT внутри той же транзакции уже может увидеть
--    строки, которые успела закоммитить другая сессия.
-- 2) В REPEATABLE READ такого уже нет:
--    транзакция работает со снимком данных на момент BEGIN.
-- 3) То есть в READ COMMITTED внутри одной транзакции результат запроса может поменяться,
--    а в REPEATABLE READ останется тем же.
-- 4) На примере tx_demo это видно по COUNT(*):
--    в READ COMMITTED число строк может стать больше,
--    а в REPEATABLE READ останется таким, каким было в начале транзакции.
