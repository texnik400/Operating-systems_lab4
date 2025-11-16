
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR/../labfiles-25"

while true; do
    echo
    echo "============== ВЫБОР ПРЕДМЕТА =============="
    echo "1) Поп-Культуроведение"
    echo "2) Цирковое_Дело"
    echo "0) Выход"
    read -rp "Ваш выбор (1-2, 0): " subj_choice

    if [ -z "$subj_choice" ]; then
        echo "Ошибка: выбор не может быть пустым. Введите 1, 2 или 0."
        continue
    fi

    case "$subj_choice" in
        0)
            echo "Выход из скрипта."
            exit 0
            ;;
        1)
            SUBJECT="Поп-Культуроведение"
            echo "Выбран предмет: $SUBJECT"
            ;;
        2)
            SUBJECT="Цирковое_Дело"
            echo "Выбран предмет: $SUBJECT"
            ;;
        *)
            echo "Некорректный выбор. Введите 1, 2 или 0."
            continue
            ;;
    esac

    SUBJECT_DIR="$BASE_DIR/$SUBJECT"
    TESTS_DIR="$SUBJECT_DIR/tests"

    if [ ! -d "$SUBJECT_DIR" ]; then
        echo "Ошибка: не найден каталог предмета: $SUBJECT_DIR" >&2
        continue
    fi
    if [ ! -d "$TESTS_DIR" ]; then
        echo "Ошибка: не найден каталог с тестами: $TESTS_DIR" >&2
        continue
    fi

    # ---------- ЦИКЛ ВЫБОРА ГРУППЫ ----------
    while true; do
        echo
        echo "Предмет: $SUBJECT"
        read -rp "Введите группу (например A-06-04/Ae-21-22, 0 — сменить предмет/выход; Ввод на англ-ом): " GROUP

        # 0 — вернуться к выбору предмета
        if [ "$GROUP" = "0" ]; then
            echo "Возврат к выбору предмета..."
            break
        fi

        if [ -z "$GROUP" ]; then
            echo "Группа не может быть пустой."
            continue
        fi

        # для сравнения внутри awk делаем верхний регистр
        GROUP_UPPER=$(echo "$GROUP" | tr '[:lower:]' '[:upper:]')

        # --- ПРОВЕРКА КОРРЕКТНОСТИ ВВОДА ГРУППЫ ---
        # ищем, есть ли такая группа хотя бы в одном файле TEST-*
        if ! awk -v grp="$GROUP_UPPER" -F';' '
            BEGIN { grp_upper = toupper(grp); found = 0 }
            {
                # первое поле — группа
                if (toupper($1) == grp_upper) { found = 1; exit }
            }
            END { exit (found ? 0 : 1) }
        ' "$TESTS_DIR"/TEST-* 2>/dev/null; then
            echo "Ошибка: группа $GROUP_UPPER не найдена в файлах тестов предмета."
            echo "Проверьте правильность ввода и попробуйте ещё раз."
            continue
        fi

        # ---------- ЦИКЛ ВЫБОРА ТЕСТА ДЛЯ ЭТОЙ ГРУППЫ ----------
        while true; do
            echo
            echo "Предмет: $SUBJECT, группа: $GROUP_UPPER"
            echo "0 — выбрать другую группу"
            read -rp "Введите номер теста: " TEST_NO

            if [ "$TEST_NO" = "0" ]; then
                echo "Возврат к выбору группы..."
                break
            fi

            if [ -з "$TEST_NO" ]; then
                echo "Номер теста не может быть пустым."
                continue
            fi

            if ! [[ "$TEST_NO" =~ ^[0-9]+$ ]]; then
                echo "Номер теста должен быть целым числом."
                continue
            fi

            TEST_FILE="$TESTS_DIR/TEST-$TEST_NO"

            if [ ! -f "$TEST_FILE" ]; then
                echo "Ошибка: файл теста TEST-$TEST_NO не найден:"
                echo "       $TEST_FILE"
                echo "Попробуйте другой номер теста или 0 для возврата к выбору группы."
                continue
            fi

            echo
            echo "=== Предмет: $SUBJECT, группа: $GROUP_UPPER, тест: $TEST_NO ==="
            echo "Поиск студентов, которые написали тест только на 2..."

            # Формат строк теста:
            # Group;Login;Date;Correct;Grade
            awk -v grp="$GROUP_UPPER" '
            BEGIN {
                grp_upper = toupper(grp)
            }
            {
                # Разбиваем строку по ;
                split($0, f, ";")
                if (length(f) < 5) next

                # Фильтруем строки по группе без учёта регистра
                if (toupper(f[1]) != grp_upper) next

                login = f[2]

                # Оценка может быть вида "2", "2-", "5+", "4--" и т.п.
                grade_str = f[5]
                gsub(/[^0-9]/, "", grade_str)
                if (grade_str == "") next
                grade = grade_str + 0

                # Запоминаем ЛУЧШУЮ оценку по этому тесту для каждого студента
                if (!(login in best) || grade > best[login]) {
                    best[login] = grade
                }
                seen[login] = 1
            }
            END {
                found = 0
                print "Студенты группы " grp " с лучшей оценкой 2 по этому тесту:"
                for (login in seen) {
                    if (best[login] == 2) {
                        print "  " login
                        found = 1
                    }
                }
                if (!found) {
                    print "Таких студентов не найдено"
                }
            }
            ' "$TEST_FILE"

            echo
            echo "Можешь ввести другой номер теста для этой группы,"
            echo "или 0 — чтобы выбрать другую группу."
        done
    done
done
