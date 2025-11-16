
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while true; do
    echo
    echo "============== Лабораторная работа №4 =============="
    echo "1) Пункт 1: лучший(ие) по посещаемости"
    echo "2) Пункт 2: не пересдавшие тест (оценка 2 или без оценки)"
    echo "3) Пункт 3: пропустили лекцию N, но сдали тест K на 5"
    echo "4) Пункт 4: лучшие результаты по годам сдачи теста"
    echo "0) Выход"
    read -rp "Ваш выбор (0-4): " choice

    if [ -z "$choice" ]; then
        echo "Ошибка: выбор не может быть пустым."
        continue
    fi

    case "$choice" in
        1)
            if [ -f "$SCRIPT_DIR/p2-1.sh" ]; then
                bash "$SCRIPT_DIR/p2-1.sh"
            else
                echo "Ошибка: не найден $SCRIPT_DIR/p2-1.sh"
            fi
            ;;
        2)
            if [ -f "$SCRIPT_DIR/p2-2.sh" ]; then
                bash "$SCRIPT_DIR/p2-2.sh"
            else
                echo "Ошибка: не найден $SCRIPT_DIR/p2-2.sh"
            fi
            ;;
        3)
            if [ -f "$SCRIPT_DIR/p3-1.sh" ]; then
                bash "$SCRIPT_DIR/p3-1.sh"
            else
                echo "Ошибка: не найден $SCRIPT_DIR/p3-1.sh"
            fi
            ;;
        4)
            if [ -f "$SCRIPT_DIR/p3-2.sh" ]; then
                bash "$SCRIPT_DIR/p3-2.sh"
            else
                echo "Ошибка: не найден $SCRIPT_DIR/p3-2.sh"
            fi
            ;;
        0)
            echo "Выход из меню."
            exit 0
            ;;
        *)
            echo "Некорректный выбор. Введите число от 0 до 4."
            ;;
    esac
done
