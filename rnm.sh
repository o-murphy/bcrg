SIZE="3m"
find ./IGLA-3M-TARGET/ -depth -type d -name "igla1-target_*" | while read dir; do
    # Отримуємо шлях до батьківської теки та поточну назву
    parent=$(dirname "$dir")
    oldname=$(basename "$dir")
    
    # Створюємо нову назву
    newname=$(echo "$oldname" | sed "s/target_/target_${SIZE}_/")
    
    # Перейменовуємо
    mv "$dir" "$parent/$newname"
done