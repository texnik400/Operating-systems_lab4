
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

    if [ ! -d "$SUBJECT_DIR" ]; then
        echo "Ошибка: не найден каталог предмета: $SUBJECT_DIR" >&2
     
        continue
    fi

    while true; do
        echo
        echo "Предмет: $SUBJECT"
        read -rp "Введите группу (например A-06-04/Ae-21-22, 0 — сменить предмет/выход; Ввод на англ-ом): " GROUP

      
        if [ "$GROUP" = "0" ]; then
            echo "Возврат к выбору предмета..."
            break      # выходим из цикла групп, снова будет выбор предмета
        fi

        if [ -z "$GROUP" ]; then
            echo "Группа не может быть пустой."
            continue
        fi

        ATT_FILE="$SUBJECT_DIR/${GROUP}-attendance"

        if [ ! -f "$ATT_FILE" ]; then
            echo "Ошибка: не найден файл посещаемости для группы $GROUP:"
            echo "       $ATT_FILE"
            echo "Попробуйте ввести другую группу или 0 для смены предмета."
            continue   # остаёмся в цикле групп
        fi

        echo
        echo "=== Предмет: $SUBJECT, группа: $GROUP ==="
        echo "Поиск студентов с лучшей посещаемостью..."

        awk '
        {
            login = $1
            bits  = $2
            cnt = gsub(/1/, "", bits)   # количество посещённых занятий
            count[login] = cnt
            if (cnt > best) {
                best = cnt
            }
        }
        END {
            if (length(count) == 0) {
                print "Нет данных по посещаемости."
                exit
            }
            print "Лучшие по посещаемости (занятий: " best "):"
            for (l in count) {
                if (count[l] == best) {
                    print "  " l
                }
            }
        }
        ' "$ATT_FILE"

        echo
        echo "Можешь ввести ещё одну группу для этого предмета,"
        echo "или 0 — чтобы выбрать другой предмет / выйти."
    done
done
