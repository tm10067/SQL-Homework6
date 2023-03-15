/* Урок 6. SQL – Транзакции. Временные таблицы, управляющие конструкции, циклы. Итоговый проект.
1. Написать функцию, которая удаляет всю информацию об указанном пользователе из БД vk. Пользователь задается по id. 
Удалить нужно все сообщения, лайки, медиа записи, профиль и запись из таблицы users. Функция должна возвращать номер пользователя.
2. Предыдущую задачу решить с помощью процедуры и обернуть используемые команды в транзакцию внутри процедуры.
3. * Написать триггер, который проверяет новое появляющееся сообщество. Длина названия сообщества (поле name) должна быть не менее 5 символов. 
Если требование не выполнено, то выбрасывать исключение с пояснением. */

USE vk;

SET GLOBAL log_bin_trust_function_creators = 1;

/* 1. Написать функцию, которая удаляет всю информацию об указанном пользователе из БД vk. Пользователь задается по id. 
Удалить нужно все сообщения, лайки, медиа записи, профиль и запись из таблицы users. Функция должна возвращать номер пользователя. */

DROP FUNCTION IF EXISTS DeleteUserFunc;

DELIMITER //

CREATE FUNCTION DeleteUserFunc (delete_user_id INT)
RETURNS INT
BEGIN

    DELETE FROM likes
     WHERE likes.user_id = delete_user_id;
    
    DELETE FROM users_communities
     WHERE users_communities.user_id = delete_user_id;
    
    DELETE FROM messages
     WHERE messages.to_user_id = delete_user_id OR messages.from_user_id = delete_user_id;
    
    DELETE FROM friend_requests
     WHERE friend_requests.initiator_user_id = delete_user_id OR friend_requests.target_user_id = delete_user_id;
    
    DELETE likes
      FROM media
      JOIN likes ON likes.media_id = media.id
     WHERE media.user_id = delete_user_id;
    
    UPDATE profiles
      JOIN media ON profiles.photo_id = media.id
       SET profiles.photo_id = NULL
     WHERE media.user_id = delete_user_id;

    DELETE FROM media
     WHERE media.user_id = delete_user_id;
    
    DELETE FROM profiles
     WHERE profiles.user_id = delete_user_id;
    
    DELETE FROM users
     WHERE users.id = delete_user_id;
    
    RETURN delete_user_id;

END; // 

DELIMITER ;

SELECT DeleteUserFunc(1) AS user_id_deleted;

/* 2. Предыдущую задачу решить с помощью процедуры и обернуть используемые команды в транзакцию внутри процедуры. */

DROP PROCEDURE IF EXISTS DeleteUserProc;

DELIMITER //

CREATE PROCEDURE DeleteUserProc(delete_user_id INT)
BEGIN

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    
    BEGIN
    
        ROLLBACK;
    
    END;

	START TRANSACTION;
    
		DELETE FROM likes
		 WHERE likes.user_id = delete_user_id;
    
		DELETE FROM users_communities
		 WHERE users_communities.user_id = delete_user_id;
    
		DELETE FROM messages
		 WHERE messages.to_user_id = delete_user_id OR messages.from_user_id = delete_user_id;
    
		DELETE FROM friend_requests
		 WHERE friend_requests.initiator_user_id = delete_user_id OR friend_requests.target_user_id = delete_user_id;
    
		DELETE likes
		  FROM media
		  JOIN likes ON likes.media_id = media.id
		 WHERE media.user_id = delete_user_id;
    
		UPDATE profiles
		  JOIN media ON profiles.photo_id = media.id
		   SET profiles.photo_id = NULL
		 WHERE media.user_id = delete_user_id;

		DELETE FROM media
		 WHERE media.user_id = delete_user_id;
    
		DELETE FROM profiles
		 WHERE profiles.user_id = delete_user_id;
    
		DELETE FROM users
		 WHERE users.id = delete_user_id;
         
	COMMIT;

END; // 

DELIMITER ;

CALL DeleteUserProc(2);

/* 3. Написать триггер, который проверяет новое появляющееся сообщество. Длина названия сообщества (поле name) должна быть не менее 5 символов. 
Если требование не выполнено, то выбрасывать исключение с пояснением. */

DROP TRIGGER IF EXISTS CommunityNameTrigger;

DELIMITER //

CREATE TRIGGER CommunityNameTrigger BEFORE INSERT ON Communities 
FOR EACH ROW BEGIN
   IF (LENGTH(new.name) < 5) THEN
       SIGNAL SQLSTATE '45000'
	   SET MESSAGE_TEXT = 'Длина названия сообщества (поле name) должна быть не менее 5 символов';
       INSERT INTO CommunityNameTrigger_exception_table VALUES();
   END IF; 
END; // 

DELIMITER ;

/* Тест триггера */

INSERT INTO Communities
VALUES (55, 'abc');

INSERT INTO Communities
VALUES (56, 'abcde');
