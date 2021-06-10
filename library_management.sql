CREATE TABLE users(
	id INT GENERATED ALWAYS AS IDENTITY,
	username VARCHAR(50) NOT NULL,
	email VARCHAR(50) UNIQUE NOT NULL,
	joining_date DATE NOT NULL DEFAULT CURRENT_DATE,
	borrowed_books INT DEFAULT 0,
	PRIMARY KEY(id)
);

INSERT INTO
	users(username,email)
VALUES
	('a','a@gmail.com'),
	('b','b@gmail.com'),
	('c','c@gmail.com');

UPDATE users SET borrowed_books = 0 WHERE id = 4;
CREATE TABLE books(
	id INT GENERATED ALWAYS AS IDENTITY,
	title VARCHAR(100) NOT NULL,
	author VARCHAR(100) NOT NULL,
	subject_category VARCHAR(100) NOT NULL,
	rack_number INT NOT NULL,
	publication_date DATE NOT NULL,
	available BOOLEAN DEFAULT true,
	reserved_by INT DEFAULT NULL,
	PRIMARY KEY(id),
	CONSTRAINT fk_reserved_by
		FOREIGN KEY(reserved_by)
			REFERENCES users(id)
);

INSERT INTO 
	books(title,author,subject_category,rack_number,publication_date)
	VALUES
		('Physics','A','study',1,CURRENT_TIMESTAMP),
		('Wings of fire','Abdul Kalam','autobiography',2,CURRENT_TIMESTAMP),
		('Manual','Acer','instructions',3,CURRENT_TIMESTAMP);
		

CREATE TABLE book_transactions(
	id INT GENERATED ALWAYS AS IDENTITY,
	borrowed_date DATE NOT NULL DEFAULT CURRENT_DATE,
	borrowed_book_id INT,
	borrower_user_id INT,
	expected_return_date DATE NOT NULL DEFAULT CURRENT_DATE + (15 * INTerval '1 day'),
	return_date DATE DEFAULT NULL,
	PRIMARY KEY(id),
	CONSTRAINT fk_borrowed_book_id
		FOREIGN KEY(borrowed_book_id)
			REFERENCES books(id),
	CONSTRAINT fk_borrower_user_id
		FOREIGN KEY(borrower_user_id)
			REFERENCES users(id)
);

CREATE TABLE fines(
	id INT GENERATED ALWAYS AS IDENTITY,
	fined_user_id INT,
	book_transaction_id INT,
	collection_status BOOLEAN DEFAULT false,
	fine_amount INT NOT NULL,
	PRIMARY KEY(id),
	CONSTRAINT fk_fined_user_id
		FOREIGN KEY(fined_user_id)
			REFERENCES users(id),
	CONSTRAINT fk_transaction_id
		FOREIGN KEY(book_transaction_id)
			REFERENCES book_transactions(id)
);

CREATE TABLE reserve_book_requests(
	id INT GENERATED ALWAYS AS IDENTITY,
	book_id INT,
	requested_by INT NOT NULL,
	PRIMARY KEY(id),
	CONSTRAINT fk_requested_by
		FOREIGN KEY(requested_by)
			REFERENCES users(id)
);

CREATE OR REPLACE FUNCTION borrow_a_book()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
	AS
$$
DECLARE
	bbooks integer;
	reserver integer;
	availability boolean;
BEGIN
	SELECT borrowed_books INTO bbooks FROM users WHERE id = NEW.borrower_user_id;
	SELECT reserved_by INTO reserver FROM books WHERE id = NEW.borrowed_book_id;
	SELECT available INTO availability FROM books WHERE id = NEW.borrowed_book_id;
	IF availability = false THEN
		RAISE EXCEPTION USING 
			MESSAGE='The requested book is not available at the moment. You can reserve it when it becomes available.';
	ELSIF reserver != NEW.borrower_user_id OR reserver != NULL THEN
		RAISE EXCEPTION USING 
			MESSAGE='The requested book is reserved by someone else.';
	ELSIF (bbooks >= 5) THEN
		RAISE EXCEPTION USING 
			MESSAGE='Users cannot borrow more than 5 books at a time';
	ELSE
		UPDATE users SET borrowed_books = (bbooks + 1) WHERE id = NEW.borrower_user_id;
		UPDATE books 
			SET available = false,
				reserved_by = NULL
		WHERE id = NEW.borrowed_book_id;
	END IF;
	RETURN NEW;
END;
$$;

CREATE TRIGGER borrow_transaction
	BEFORE INSERT
	ON book_transactions
	FOR EACH ROW
	EXECUTE PROCEDURE borrow_a_book();
	
CREATE OR REPLACE FUNCTION return_a_book()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
	AS
$$
DECLARE
	date_of_return integer := EXTRACT('day' FROM OLD.return_date);
BEGIN
	IF (date_of_return > 1) THEN
		RAISE EXCEPTION USING 
			MESSAGE='Cannot return an already returned book';
	ELSE
		UPDATE books SET available = true WHERE id = OLD.borrowed_book_id;
		UPDATE users SET borrowed_books = borrowed_books - 1 WHERE id = OLD.borrower_user_id;
	END IF;
	RETURN NEW;
END;
$$;

CREATE TRIGGER return_transaction
	BEFORE UPDATE
	ON book_transactions
	FOR EACH ROW
	EXECUTE PROCEDURE return_a_book();

CREATE OR REPLACE FUNCTION check_and_add_fines()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
	AS
$$
DECLARE
	expected_return_date integer:= EXTRACT('day' FROM NEW.expected_return_date);
	actual_return_date integer:= EXTRACT('day' FROM NEW.return_date);
	difference integer:= (actual_return_date - expected_return_date);
	fine_value integer:= (20 * difference);
BEGIN
	IF difference > 1 THEN
		INSERT INTO fines(fined_user_id,book_transaction_id,fine_amount)
		VALUES(NEW.borrower_user_id,NEW.transaction_id,fine_value);
	END IF;
	RETURN NEW;
END;
$$;

CREATE TRIGGER check_and_add_fine
	AFTER UPDATE
	ON book_transactions
	FOR EACH ROW
	EXECUTE PROCEDURE check_and_add_fines();

CREATE OR REPLACE FUNCTION reserve_a_book()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
	AS
$$
DECLARE
	book_available boolean;
BEGIN
	SELECT available INTO book_available FROM books WHERE id = NEW.book_id;
	IF (book_available = true) THEN
		RAISE EXCEPTION USING
			MESSAGE = 'Cannot reserve an already available book';
	END IF;
	UPDATE books SET reserved_by = NEW.requested_by WHERE id = NEW.book_id;
	RETURN NEW;
END;
$$;
CREATE TRIGGER request_reserve
	BEFORE INSERT
	ON reserve_book_requests
	FOR EACH ROW
	EXECUTE PROCEDURE reserve_a_book();

 

