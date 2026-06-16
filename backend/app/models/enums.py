from enum import Enum

class EDifficulty(str, Enum):
    easy = "Легкая"
    medium = "Средняя"
    hard = "Сложная"

class EImportance(str, Enum):
    low = "Низкая"
    medium = "Средняя"
    high = "Высокая"