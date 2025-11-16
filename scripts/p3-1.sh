
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

  
    while true; do
        echo
        echo "Предмет: $SUBJECT"
        read -rp "Введите группу (например A-06-04/Ae-21-22, 0 — сменить предмет/выход; Ввод на англ-ом): " GROUP

       
        if [ "$GROUP" = "0" ]; then
            echo "Возврат к выбору предмета..."
            break
        fi

        if [ -z "$GROUP" ]; then
            echo "Группа не может быть пустой."
            continue
        fi

        GROUP_UPPER=$(echo "$GROUP" | tr '[:lower:]' '[:upper:]')

        ATT_FILE="$SUBJECT_DIR/${GROUP_UPPER}-attendance"

        if [ ! -f "$ATT_FILE" ]; then
            echo "Ошибка: не найден файл посещаемости для группы $GROUP_UPPER:"
            echo "       $ATT_FILE"
            echo "Проверьте название группы и попробуйте ещё раз."
            continue
        fi

        # Узнаём количество лекций (длина строки из 0/1)
        MAX_LECTURES=$(awk 'NR==1 { print length($2); exit }' "$ATT_FILE")
        if [ -z "$MAX_LECTURES" ]; then
            echo "Ошибка: файл посещаемости пуст или имеет неверный формат."
            continue
        fi

        echo "Для группы $GROUP_UPPER найдено занятий: $MAX_LECTURES"

      
        while true; do
            echo
            echo "Предмет: $SUBJECT, группа: $GROUP_UPPER"
            echo "0 — выбрать другую группу"
            read -rp "Введите номер лекции N (1..$MAX_LECTURES): " LEC_NO

            if [ "$LEC_NO" = "0" ]; then
                echo "Возврат к выбору группы..."
                break
            fi

            if [ -z "$LEC_NO" ]; then
                echo "Номер лекции не может быть пустым."
                continue
            fi

            if ! [[ "$LEC_NO" =~ ^[0-9]+$ ]]; then
                echo "Номер лекции должен быть целым числом."
                continue
            fi

            if [ "$LEC_NO" -lt 1 ] || [ "$LEC_NO" -gt "$MAX_LECTURES" ]; then
                echo "Номер лекции должен быть от 1 до $MAX_LECTURES."
                continue
            fi

            read -rp "Введите номер теста K (0 — выбрать другую группу): " TEST_NO

            if [ "$TEST_NO" = "0" ]; then
                echo "Возврат к выбору группы..."
                break
            fi

            if [ -z "$TEST_NO" ]; then
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
            echo "=== Предмет: $SUBJECT, группа: $GROUP_UPPER, лекция N=$LEC_NO, тест K=$TEST_NO ==="
            echo "Поиск студентов, пропустивших лекцию и сдавших тест на 5..."

           
            awk -v grp="$GROUP_UPPER" -v lec="$LEC_NO" -v testno="$TEST_NO" '
            BEGIN {
                grp_upper = toupper(grp)
            }
            NR==FNR {
                # Первый файл — посещаемость: отмечаем, кто ПРОПУСТИЛ лекцию lec
                login = $1
                bits  = $2
                if (lec <= length(bits)) {
                    b = substr(bits, lec, 1)
                    if (b == "0") {
                        missed[login] = 1
                    }
                }
                next
            }
            {
                # Второй файл — TEST-K
                split($0, f, ";")
                if (length(f) < 5) next

                # Группа должна совпадать (без учёта регистра)
                if (toupper(f[1]) != grp_upper) next

                login = f[2]

                # Оценка может быть "5", "5+", "5--" и т.п.
                grade_str = f[5]
                gsub(/[^0-9]/, "", grade_str)
                if (grade_str == "") next
                grade = grade_str + 0

                # Запоминаем ЛУЧШУЮ оценку по этому тесту
                if (!(login in best_grade) || grade > best_grade[login]) {
                    best_grade[login] = grade
                }
                seen[login] = 1
            }
            END {
                found = 0
                print "Студенты группы " grp " пропустившие лекцию " lec " и сдавшие тест " testno " на 5:"
                for (login in missed) {
                    if (login in best_grade && best_grade[login] == 5) {
                        print "  " login
                        found = 1
                    }
                }
                if (!found) {
                    print "Таких студентов не найдено"
                }
            }
            ' "$ATT_FILE" "$TEST_FILE"

            echo
            echo "Можешь ввести другие N и K для этой же группы,"
            echo "или 0 при вводе N/K — чтобы выбрать другую группу."
        done
    done
done
