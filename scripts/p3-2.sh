
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
            echo "Выход."
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
        echo "0 — сменить предмет"
        read -rp "Введите номер теста (например 1,2,...): " TEST_NO

        if [ "$TEST_NO" = "0" ]; then
            echo "Возврат к выбору предмета..."
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
            echo "Попробуйте другой номер теста или 0 для возврата к выбору предмета."
            continue
        fi

        echo
        echo "=== Предмет: $SUBJECT, тест: TEST-$TEST_NO ==="
        echo "Поиск студентов с лучшими результатами по годам (по количеству правильных ответов)..."

     
        awk '
        BEGIN {
            FS = ";"
        }
        {
            if (NF < 4) next

            group   = $1      # группа
            login   = $2      # ФИО/логин
            date    = $3      # дата
            correct = $4 + 0  # количество правильных ответов

            # Берём год как первые 4 символа даты (подходит для "2007-09-21" и "2007 September")
            year = substr(date, 1, 4)
            if (year !~ /^[0-9][0-9][0-9][0-9]$/) next

            key = year "|" group "|" login

            # максимальное число правильных ответов по этому году
            if ( !(year in best_year) || correct > best_year[year] ) {
                best_year[year] = correct
            }

            # лучший результат конкретного студента (группа+логин) в этом году
            if ( !(key in best_student) || correct > best_student[key] ) {
                best_student[key] = correct
            }

            years[year] = 1
        }
        END {
            have = 0
            for (y in years) { have = 1; break }

            if (!have) {
                print "Нет данных по этому тесту для выбранного предмета."
                exit
            }

            print "Лучшие результаты по годам сдачи теста:"
            for (y in years) {
                maxc = best_year[y]
                print "Год " y ", максимальное количество правильных ответов: " maxc
                print "  Студенты (группа, ФИО):"
                for (k in best_student) {
                    split(k, a, "|")
                    year_k  = a[1]
                    group_k = a[2]
                    login_k = a[3]
                    if (year_k == y && best_student[k] == maxc) {
                        # раньше тут было ещё количество баллов, теперь только группа + ФИО
                        print "    " group_k ", " login_k
                    }
                }
            }
        }
        ' "$TEST_FILE"

        echo
        echo "Можешь ввести другой номер теста для этого предмета,"
        echo "или 0 — чтобы выбрать другой предмет."
    done
done
