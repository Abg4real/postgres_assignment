## Library Management System

##### This library management system provides following functionalities:
1. create users
```
INSERT INTO users(username,email) VALUES(YOUR_VALUES)
```
2. Borrow a book
```
INSERT INTO book_transactions(borrowed_book_id,borrower_user_id) VALUES(YOUR_VALUES)
```
3. Return a book
```
UPDATE book_transactions SET return_date = YOUR_VALUE WHERE id = YOUR_VALUE
```
4. View Your fines if any
```
SELECT * FROM fines WHERE fined_user_id = YOUR_VALUE
```
5. Collect Fine
```
UPDATE fines SET collection_status = true WHERE id = YOUR_VALUE
```
6. Search For books
```
SELECT * FROM book WHERE YOUR_CRITERIA = YOUR_VALUE
```
Criterias for search are: id, title, author, rack_number, publication_date,subject_category.
7. Reserve a book if not available
```
INSERT INTO reserve_book_requests(book_id,requested_by) VALUES(YOUR_VALUES);
```

The system has following features:
*  Search based upon various criterias
*  User cannot borrow a reserved or currently unavailable book
*  User cannot borrow more than 5 books before they are returned
*  User cannot return an already reserved book
*  If the user returns the book after 15 days, fine is automatically generated
*  User can reserve a book if it is not available currently
*  User cannot reserve an already available book