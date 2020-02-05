\c tdl;
\set AUTOCOMMIT off

BEGIN;

CREATE OR REPLACE FUNCTION select_user_id_by_username(VARCHAR) RETURNS TABLE (
    id BIGINT
)
AS
$$
BEGIN
    RETURN QUERY
    SELECT user_account.id FROM user_account
    WHERE user_account.username = $1;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_password(BIGINT, VARCHAR) RETURNS TABLE (
    id BIGINT
)
AS
$$
BEGIN
    RETURN QUERY
    SELECT user_account.id FROM user_account
    WHERE user_account.id = $1 AND user_account.password = $2;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_user(VARCHAR, VARCHAR) RETURNS VOID AS
$$
BEGIN
    IF NOT EXISTS (SELECT id FROM select_user_id_by_username($1)) THEN
        INSERT INTO user_account (username, password)
        VALUES (
            $1,
            $2
        );
        
        INSERT INTO user_additional_info (user_id)
        VALUES (
            (SELECT id FROM user_account WHERE username = $1)
        );
    END IF;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_user(BIGINT) RETURNS VOID AS
$$
BEGIN
    IF EXISTS (SELECT 1 FROM user_account WHERE user_account.id = $1) THEN
        DELETE FROM note
        WHERE note.user_id = $1;
        
        DELETE FROM user_additional_info
        WHERE user_additional_info.user_id = (SELECT id FROM user_account WHERE id = $1);
        
        DELETE FROM user_account
        WHERE user_account.id = $1;
    END IF;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_note(BIGINT, VARCHAR, BIGINT) RETURNS VOID AS
$$
DECLARE
    new_prio BIGINT := $3;
    max_prio BIGINT := (SELECT COUNT(*) FROM note WHERE note.user_id = $1);
BEGIN
    IF EXISTS (SELECT 1 FROM user_account WHERE user_account.id = $1) THEN
        IF new_prio > max_prio THEN
            new_prio = max_prio + 1;
        ELSIF new_prio <= 0 THEN
            new_prio = 1;
        END IF;
        
        UPDATE note SET priority = priority + 1
        WHERE user_id = $1 AND priority >= new_prio;
        
        INSERT INTO note (user_id, headline, priority) VALUES (
            (SELECT id FROM user_account WHERE id = $1),
            $2,
            new_prio
        );
    END IF;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_note(BIGINT, BIGINT) RETURNS VOID AS
$$
DECLARE
    old_prio BIGINT := (SELECT priority FROM note WHERE note.user_id = $1 AND note.id = $2);
BEGIN
    IF EXISTS (SELECT 1 FROM user_account WHERE user_account.id = $1) THEN       
        DELETE FROM note
        WHERE note.user_id = $1 AND note.id = $2;
        
        UPDATE note SET priority = priority - 1
        WHERE user_id = $1 AND priority >= old_prio;
    END IF;
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION show_user_notes(BIGINT)
RETURNS TABLE (
    user_id BIGINT,
    username VARCHAR,
    note_id BIGINT,
    headline VARCHAR,
    priority BIGINT,
    status BOOL,
    date_created TIMESTAMPTZ
)
AS
$$
BEGIN
    IF EXISTS (SELECT 1 FROM user_account WHERE user_account.id = $1) THEN
        RETURN QUERY
        SELECT
            user_account.id,
            user_account.username,
            note.id,
            note.headline,
            note.priority,
            note.status,
            note.date_created
        FROM user_account
        INNER JOIN note
        ON user_account.id = note.user_id
        WHERE user_account.id = $1
        ORDER BY note.priority ASC;
    END IF;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_priority(BIGINT, BIGINT, BIGINT) RETURNS VOID AS
$$
DECLARE
    new_prio BIGINT := $3;
    max_prio BIGINT := (SELECT COUNT(*) FROM note WHERE note.user_id = $1);
    old_prio BIGINT := (SELECT priority FROM note WHERE note.user_id = $1 AND note.id = $2);
BEGIN
    IF new_prio > max_prio THEN
        new_prio = max_prio;
    ELSIF new_prio <= 0 THEN
        new_prio = 1;
    END IF;
    
    UPDATE note SET priority = priority - 1
    WHERE user_id = $1 AND priority > old_prio AND priority <= new_prio;
    
    UPDATE note SET priority = priority + 1
    WHERE user_id = $1 AND priority >= new_prio AND priority < old_prio;
            
    UPDATE note SET priority = new_prio
    WHERE user_id = $1 AND id = $2;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION select_max_priority(BIGINT) RETURNS TABLE (
    priority BIGINT
)
AS
$$
BEGIN
    RETURN QUERY
    SELECT note.priority FROM note
    WHERE note.user_id = $1
    ORDER BY priority DESC
    LIMIT 1;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION change_status(BIGINT, BIGINT) RETURNS VOID
AS
$$
BEGIN
    UPDATE note SET status = NOT status
    WHERE user_id = $1 AND id = $2;
END
$$ LANGUAGE plpgsql;

COMMIT;
