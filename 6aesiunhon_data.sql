CREATE DATABASE Sixaesiunhon;
GO

USE Sixaesiunhon;
GO

-- Roles
CREATE TABLE Roles (
    RoleID INT PRIMARY KEY IDENTITY(1,1),
    RoleName NVARCHAR(50) NOT NULL UNIQUE
);
GO

INSERT INTO Roles (RoleName)
VALUES ('Admin'), ('Manager'), ('Sales Staff'), ('Warehouse Staff');

-- Employees
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    UserCode NVARCHAR(20) UNIQUE NULL, -- AD01
    Username VARCHAR(100) UNIQUE NOT NULL, -- Không trùng lặp
    Password NVARCHAR(255) NOT NULL, -- Password được mã hóa
    FullName NVARCHAR(100)NULL,
    Phone NVARCHAR(20) UNIQUE NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    RoleID INT NOT NULL,
	RoleName NVARCHAR(50),
    FOREIGN KEY (RoleID) REFERENCES Roles(RoleID) ON DELETE CASCADE
);
GO

CREATE TRIGGER trg_Generate_UserCode
ON Users
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserID INT, @RoleID INT, @RoleCode NVARCHAR(5);
    DECLARE @Username VARCHAR(100), @Password NVARCHAR(255), @FullName NVARCHAR(100);
    DECLARE @Phone NVARCHAR(20), @Email NVARCHAR(100), @NextUserCode NVARCHAR(20);
    
    -- CURSOR để duyệt qua từng dòng dữ liệu mới
    DECLARE cur CURSOR FOR
    SELECT RoleID, Username, Password, FullName, Phone, Email FROM inserted;

    OPEN cur;
    FETCH NEXT FROM cur INTO @RoleID, @Username, @Password, @FullName, @Phone, @Email;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Lấy RoleCode tương ứng
        SELECT @RoleCode = 
            CASE 
                WHEN RoleName = 'Admin' THEN 'AD'
                WHEN RoleName = 'Manager' THEN 'MN'
                WHEN RoleName = 'Sales Staff' THEN 'SS'
                WHEN RoleName = 'Warehouse Staff' THEN 'WS'
                ELSE 'OT' 
            END
        FROM Roles WHERE RoleID = @RoleID;

        -- Tìm số lớn nhất hiện tại trong bảng Users
        SELECT @NextUserCode = @RoleCode + 
            RIGHT('00' + CAST(COALESCE(MAX(CAST(SUBSTRING(UserCode, 3, 2) AS INT)), 0) + 1 AS NVARCHAR), 2)
        FROM Users WHERE UserCode LIKE @RoleCode + '%';

        -- Chèn bản ghi vào Users với UserCode mới
        INSERT INTO Users (UserCode, Username, Password, FullName, Phone, Email, RoleID)
        VALUES (@NextUserCode, @Username, @Password, @FullName, @Phone, @Email, @RoleID);

        FETCH NEXT FROM cur INTO @RoleID, @Username, @Password, @FullName, @Phone, @Email;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;
GO


CREATE TRIGGER trg_SetRoleName
ON Users
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE u
    SET u.RoleName = r.RoleName
    FROM Users u
    JOIN inserted i ON u.UserID = i.UserID
    JOIN Roles r ON i.RoleID = r.RoleID;
END;
GO


INSERT INTO Users (Username, Password, FullName, Phone, Email, RoleID)  
VALUES  
    ('admin01', 'linlinAD01', N'Linlin', '0987654321', 'nq2019.nguyenthitrucmai180504@gmail.com', 1),  
    ('manager01', 'kaMN01', N'Chim Sơn Ka', '0978543210', 'anhkhoa08032004@gmail.com', 2),  
    ('sales01', 'yukiSS01', N'Yuki', '0965432109', 'huynhnguyenkieumy123@gmail.com', 3),  
    ('sales02', 'sleepSS02', N'Hay Ngủ Gật', '0978432109', 'hieu190604@gmail.com', 3), 
    ('warehouse01', 'nonWH01', N'Đổ Văn Non', '0954321098', 'dpt12032004@gmail.com', 4),
    ('warehouse02', 'chiWH02', N'Chắc Chăm Chỉ', '0954432109', 'sonpham2004123@gmail.com', 4); 


-- Customers
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    CustomerCode NVARCHAR(20) NULL, -- Để NULL để trigger cập nhật
    CustomerName NVARCHAR(100) NOT NULL,
    Gender NVARCHAR(10) NOT NULL CHECK (Gender IN ('Male', 'Female')),
    Phone NVARCHAR(20) NOT NULL,
    Email NVARCHAR(100) UNIQUE,
    Address NVARCHAR(100) NOT NULL,
    MembershipLevel NVARCHAR(10) NOT NULL CHECK (MembershipLevel IN ('Regular', 'VIP' )),
    ParticipateIn DATETIME DEFAULT GETDATE()
);
GO

-- Trigger để tự động tạo mã khách hàng
CREATE TRIGGER trg_GenerateCustomerCode
ON Customers
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Cập nhật CustomerCode dựa vào CustomerID
    UPDATE c
    SET CustomerCode = 
        'CUS' + CAST(YEAR(GETDATE()) AS NVARCHAR(4)) + '-' + 
        RIGHT('000' + CAST(c.CustomerID AS NVARCHAR(10)), 3) -- Định dạng ID thành 001, 002, 003
    FROM Customers c
    INNER JOIN inserted i ON c.CustomerID = i.CustomerID;
END;
GO

INSERT INTO Customers (CustomerName, Gender, Phone, Email, Address, MembershipLevel)
VALUES
    (N'Văn Kiệt', 'Male', '0987654321', 'kiet123@example.com', N'123 Lê Lợi, Quận 1, TP.HCM', 'Regular'),
    (N'Takahashi Haruto', 'Male', '+81 3-1234-5678', 'takahashiharuto@example.jp', N'Chiyoda, Tokyo, Japan', 'Regular'),
    (N'Lê Hoàng Tuyết', 'Male', '0965432109', 'ssnow09@example.com', N'789 Trần Phú, Quận 5, TP.HCM', 'Regular'),
    (N'Phạm Minh Duy', 'Female', '0954321098', 'duyhd@example.com', N'101 Hùng Vương, Quận 10, TP.HCM', 'VIP'),
    (N'Bùi Văn Ngọc', 'Male', '0943210987', 'buingoc@example.com', N'202 Hai Bà Trưng, Quận 3, TP.HCM', 'Regular'),
    (N'Olga Petrova', 'Female', '+7 495 123-45-67', 'olgapetrova@example.ru', N'Tverskaya Street, Moscow, Russia', 'VIP'),
    (N'Đỗ Quang', 'Male', '0921098765', 'doquangg@example.com', N'404 Phan Xích Long, Phú Nhuận, TP.HCM', 'Regular'),
    (N'Carlos Rodríguez', 'Male', '+34 91 123 4567', 'carlosrodriguez@example.es', N'Gran Vía, Madrid, Spain', 'Regular'),
    (N'Maria Oliveira', 'Female', '+55 11 91234-5678', 'mariaoliveira@example.br', N'Avenida Paulista, São Paulo, Brazil', 'Regular'),
    (N'Lý Thanh Thanh', 'Female', '0898765432', 'lythanhj@example.com', N'707 Nguyễn Đình Chiểu, Quận 1, TP.HCM', 'VIP'),
    (N'Vũ Bonny', 'Male', '0887654321', 'vuhailk@example.com', N'808 Hoàng Văn Thụ, Tân Bình, TP.HCM', 'Regular'),
    (N'Mai Phương Lily', 'Female', '0876543210', 'maiphuongl@example.com', N'909 Điện Biên Phủ, Bình Thạnh, TP.HCM', 'VIP'),
	(N'Nguyễn Hoàng Nam', 'Male', '0912345678', 'nguyenhoangnam@example.com', N'12 Trần Hưng Đạo, Quận Hải Châu, Đà Nẵng', 'Regular'),
    (N'Trần Duy Ly', 'Female', '0923456789', 'DLTran@example.com', N'56 Lê Lợi, Quận Ngô Quyền, Hải Phòng', 'Regular'),
    (N'Lê Ayato', 'Male', '0934567890', 'ayatone@example.com', N'78 Nguyễn Huệ, Quận Ninh Kiều, Cần Thơ', 'Regular'),
    (N'Lâm Thanh Tâm', 'Female', '0945678901', 'thanhtam@example.com', N'90 Quang Trung, Quận Thanh Khê, Đà Nẵng', 'VIP'),
    (N'Đặng Quốc Hùng', 'Male', '0956789012', 'dangquochung@example.com', N'123 Phạm Ngũ Lão, TP. Nha Trang, Khánh Hòa', 'Regular'),
    (N'Đinh Lệ Tranh', 'Male', '0967890123', 'draw@example.com', N'234 Nguyễn Văn Cừ, TP. Quy Nhơn, Bình Định', 'VIP'),
    (N'Hoàng Văn Khánh', 'Male', '0978901234', 'hoangvankhanh@example.com', N'345 Trần Phú, TP. Huế, Thừa Thiên Huế', 'Regular'),
    (N'Hans Müller', 'Male', '+49 30 123456', 'hansmuller@example.de', N'Unter den Linden 5, Berlin, Germany', 'Regular');


-- Categories
CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) UNIQUE NOT NULL
);
GO

INSERT INTO Categories (CategoryName)
VALUES ('Ice Skates'), ('Apparel'), ('Accessories'), ('Protective Gear'), ('Training Aids'), ('Skate Maintenence'), ('Kid’s Gear'), ('Gift & Souvenirs');
-- Giày trượt băng, Trang phục, Phụ kiện, Dụng cụ bảo vệ, Dụng cụ luyệ tập, Bảo dưỡng giày, Đồ cho trẻ em, Quà lưu niệm

-- CategoryCodes
CREATE TABLE CategoryCodes (
    CategoryID INT PRIMARY KEY,
    ShortCode NVARCHAR(20) UNIQUE NOT NULL
);

INSERT INTO CategoryCodes (CategoryID, ShortCode)
VALUES
    (1, 'Skates'),
    (2, 'Apparel'),
    (3, 'Access'),
    (4, 'Protect'),
    (5, 'Train'),
    (6, 'Maintain'),
    (7, 'Kid'),
    (8, 'Gifts');


-- Suppliers
CREATE TABLE Suppliers (
    SupplierID INT PRIMARY KEY IDENTITY(1,1),
    SupplierName NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20),
    Email NVARCHAR(100),
    Address NVARCHAR(255) NOT NULL
);
GO

INSERT INTO Suppliers (SupplierName, Phone, Email, Address)  
VALUES  
    (N'HVC Group', '024-1234-5678', 'contact@hvcgroup.vn', N'Hà Nội, Việt Nam'),  
    (N'Vincom Ice Rink', '028-9876-5432', 'info@vincomicerink.vn', N'TP. Hồ Chí Minh, Việt Nam'),  
    (N'Giày trượt băng Việt Nam', '0909-876-543', 'support@giaytruotbang.vn', N'Việt Nam'),  
    (N'Jackson Ultima Skates', '+1-905-819-3100', 'sales@jacksonultima.com', N'Cambridge, Ontario, Canada'),  
    (N'Riedell Skates', '+1-800-698-6893', 'info@riedellskates.com', N'Red Wing, Minnesota, USA');


-- Products
CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductCode NVARCHAR(20) NULL, 
    SupplierID INT,
    ProductName NVARCHAR(100) NULL,
    Price DECIMAL(18,2) NOT NULL,
    Stock INT NOT NULL, 
    GoodsReceipt DATETIME DEFAULT GETDATE(), -- Ngày nhập hàng
    CategoryID INT NOT NULL, -- Sửa tên cột để khớp với khóa ngoại
	CategoryName NVARCHAR(100),
    Description NVARCHAR(MAX) NOT NULL,
    ImageURL NVARCHAR(500),
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);
GO

CREATE TRIGGER trg_GenerateProductCode
ON Products
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET p.ProductCode = (
        SELECT c.ShortCode + FORMAT(i.ProductID, '000')
        FROM Categories ca
        JOIN CategoryCodes c ON ca.CategoryID = c.CategoryID
        WHERE ca.CategoryID = i.CategoryID
    )
    FROM Products p
    INNER JOIN inserted i ON p.ProductID = i.ProductID;
END;
GO

CREATE TRIGGER trg_SetCategoryName
ON Products
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET p.CategoryName = c.CategoryName
    FROM Products p
    JOIN inserted i ON p.ProductID = i.ProductID
    JOIN Categories c ON i.CategoryID = c.CategoryID;
END;
GO


INSERT INTO Products (SupplierID, ProductName, Price, Stock, CategoryID, Description, ImageURL)
VALUES  
    -- Skates (Giày trượt băng)
    (1, N'Giày trượt băng HVC Pro', 3200000, 10, 1, N'Giày trượt băng chuyên nghiệp từ HVC Group', 'https://example.com/hvc-pro.jpg'),
    (4, N'Giày trượt băng Jackson Ultima Elite', 5800000, 4, 1, N'Giày trượt băng chuyên nghiệp dành cho vận động viên', 'https://example.com/jackson-elite.jpg'),
    (3, N'Giày trượt băng Việt Nam Basic', 2600000, 20, 1, N'Mẫu giày trượt băng phổ thông, phù hợp với mọi cấp độ', 'https://example.com/vietnam-basic.jpg'),
    (5, N'Giày trượt băng Riedell Classic', 4200000, 6, 1, N'Giày trượt băng cổ điển, thiết kế bền đẹp', 'https://example.com/riedell-classic.jpg'),

    -- Apparel (Trang phục trượt băng)
    (2, N'Áo khoác trượt băng Vincom', 850000, 20, 2, N'Áo khoác giữ nhiệt chuyên dụng cho trượt băng', 'https://example.com/vincom-jacket.jpg'),
    (3, N'Bộ quần áo trượt băng chuyên nghiệp', 1750000, 15, 2, N'Bộ trang phục biểu diễn trượt băng nghệ thuật', 'https://example.com/pro-skating-outfit.jpg'),
	(2, N'Váy trượt băng nghệ thuật lấp lánh', 2100000, 10, 2, N'Váy thi đấu trượt băng nghệ thuật thiết kế sang trọng', 'https://example.com/sparkle-dress.jpg'),
    (4, N'Quần leggings trượt băng co giãn', 700000, 25, 2, N'Quần leggings giữ nhiệt, co giãn tốt khi luyện tập', 'https://example.com/skating-leggings.jpg'),
    (5, N'Áo len dài tay giữ nhiệt', 900000, 18, 2, N'Áo len cao cấp giúp giữ ấm khi tập luyện trượt băng', 'https://example.com/warm-skating-shirt.jpg'),

    -- Accessories (Phụ kiện)
    (3, N'Balo đựng giày trượt', 450000, 15, 3, N'Balo chuyên dụng để đựng giày trượt băng', 'https://example.com/skate-bag.jpg'),
    (2, N'Túi đựng giày trượt băng Vincom', 550000, 12, 3, N'Túi vải chống nước để bảo vệ giày trượt băng', 'https://example.com/skate-bag-vincom.jpg'),
	(4, N'Vớ chuyên dụng cho trượt băng', 250000, 30, 3, N'Vớ giữ ấm và chống trơn khi trượt băng', 'https://example.com/skating-socks.jpg'),
    (5, N'Bọc lưỡi dao trượt băng Silicon', 300000, 20, 3, N'Bọc bảo vệ lưỡi dao khi không sử dụng', 'https://example.com/blade-covers.jpg'),
    (3, N'Dây giày trượt băng siêu bền', 150000, 50, 3, N'Dây giày trượt băng chắc chắn, chống tuột', 'https://example.com/skate-laces.jpg'),
	-- Blades (Lưỡi dao trượt băng)
    (4, N'Lưỡi dao Jackson Ultima Matrix', 3200000, 5, 3, N'Lưỡi dao chuyên nghiệp cho vận động viên trượt băng nghệ thuật', 'https://example.com/matrix-blade.jpg'),
    (5, N'Lưỡi dao Riedell Eclipse', 2800000, 6, 3, N'Lưỡi dao chất lượng cao giúp tăng độ ổn định khi trượt', 'https://example.com/eclipse-blade.jpg'),
    (3, N'Lưỡi dao trượt băng Việt Nam Standard', 1500000, 10, 3, N'Lưỡi dao trượt băng phổ thông, phù hợp với mọi cấp độ', 'https://example.com/vn-standard-blade.jpg'),
    (2, N'Lưỡi dao trượt băng Vincom Pro', 2600000, 7, 3, N'Lưỡi dao thiết kế đặc biệt giúp tối ưu hóa tốc độ', 'https://example.com/vincom-pro-blade.jpg'),

    -- Protection (Bảo hộ)
    (4, N'Bảo hộ cổ chân Jackson', 650000, 25, 4, N'Bảo hộ cổ chân giúp hạn chế chấn thương khi trượt băng', 'https://example.com/ankle-guard.jpg'),
    (4, N'Găng tay bảo hộ Riedell', 350000, 30, 4, N'Găng tay giúp bảo vệ bàn tay khi trượt băng', 'https://example.com/gloves.jpg'),
    (4, N'Nón bảo hiểm trượt băng Vincom', 900000, 12, 4, N'Nón bảo hiểm chuyên dụng khi luyện tập', 'https://example.com/helmet.jpg'),
    (5, N'Bộ bảo hộ đầu gối và khuỷu tay', 750000, 18, 4, N'Bộ bảo hộ giúp giảm thiểu chấn thương khi ngã', 'https://example.com/knee-elbow-pads.jpg'),

    -- Training (Hướng dẫn & huấn luyện)
    (5, N'Đĩa hướng dẫn kỹ thuật Riedell', 300000, 30, 5, N'Đĩa DVD hướng dẫn kỹ thuật trượt băng từ Riedell', 'https://example.com/training-dvd.jpg'),
    (5, N'Bảng hướng dẫn động tác cơ bản', 500000, 10, 5, N'Bảng chỉ dẫn giúp người mới học trượt băng dễ dàng hơn', 'https://example.com/training-board.jpg'),
    (5, N'Sách hướng dẫn kỹ thuật nâng cao', 750000, 8, 5, N'Sách chuyên sâu về kỹ thuật trượt băng nghệ thuật', 'https://example.com/advanced-skating-book.jpg'),

    -- Maintenance (Bảo dưỡng)
    (1, N'Bộ dụng cụ bảo dưỡng giày HVC', 500000, 12, 6, N'Bộ dụng cụ giúp bảo trì và vệ sinh giày trượt băng', 'https://example.com/maintenance-kit.jpg'),
    (2, N'Dung dịch làm sạch giày trượt băng', 300000, 20, 6, N'Dung dịch vệ sinh chuyên dụng giúp bảo quản giày', 'https://example.com/cleaning-liquid.jpg'),

    -- Kid (Trẻ em)
    (2, N'Giày trượt băng trẻ em Vincom', 2500000, 8, 7, N'Giày trượt băng dành riêng cho trẻ em', 'https://example.com/kid-skates.jpg'),
    (3, N'Bộ bảo hộ trượt băng cho trẻ em', 650000, 15, 7, N'Bộ bảo hộ gồm mũ bảo hiểm, găng tay và miếng bảo vệ', 'https://example.com/kid-protection-set.jpg'),

    -- Gifts (Quà tặng)
    (3, N'Búp bê trượt băng phiên bản đặc biệt', 600000, 18, 8, N'Búp bê mô phỏng vận động viên trượt băng', 'https://example.com/skating-doll.jpg'),
    (5, N'Móc khóa giày trượt băng', 150000, 50, 8, N'Móc khóa mini hình giày trượt băng', 'https://example.com/skate-keychain.jpg');


-- Orders
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    OrderCode NVARCHAR(20) NULL, 
    CustomerID INT NULL, -- Cho phép NULL nếu là khách hàng mới
    CustomerCode NVARCHAR(20) NULL, -- Để NULL để trigger cập nhật
    CustomerName NVARCHAR(100) NULL,
    UserID INT NULL, -- Cho phép NULL nếu đơn hàng không có nhân viên xử lý
    UserCode NVARCHAR(20) NULL, -- AD01
    FullName NVARCHAR(100) NULL,
    TotalPrice DECIMAL(18,2) NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    PaymentStatus NVARCHAR(50) CHECK (PaymentStatus IN ('Pending', 'Paid', 'Shipped', 'Completed', 'Cancelled', 'Refunded')) DEFAULT 'Pending', -- Kiểm tra trạng thái đơn 
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON DELETE CASCADE,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE SET NULL
);
GO


-- Trigger để tự động tạo mã đơn hàng
CREATE TRIGGER trg_GenerateOrderCode
ON Orders
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Cập nhật OrderCode dựa vào CustomerID
    UPDATE c
    SET OrderCode = 
        'ORD' + CAST(YEAR(GETDATE()) AS NVARCHAR(4)) + '-' + 
        RIGHT('00' + CAST(c.OrderID AS NVARCHAR(10)), 2) -- Định dạng ID thành 01, 02, 03
    FROM Orders c
    INNER JOIN inserted i ON c.OrderID = i.OrderID;
END;
GO


-- Cập nhật thông tin khách hàng và nhân viên vào đơn hàng
UPDATE o
SET 
    o.CustomerCode = c.CustomerCode,
    o.CustomerName = c.CustomerName,
    o.UserCode = u.UserCode,
    o.FullName = u.FullName
FROM Orders o
LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
LEFT JOIN Users u ON o.UserID = u.UserID
WHERE o.CustomerCode IS NULL OR o.CustomerName IS NULL OR o.UserCode IS NULL OR o.FullName IS NULL;
GO

-- Trigger cập nhật tự động khi có đơn hàng mới
CREATE TRIGGER trg_UpdateCustomerUser
ON Orders
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE o
    SET 
        o.CustomerCode = c.CustomerCode,
        o.CustomerName = c.CustomerName,
        o.UserCode = u.UserCode,
        o.FullName = u.FullName
    FROM Orders o
    JOIN inserted i ON o.OrderID = i.OrderID
    LEFT JOIN Customers c ON i.CustomerID = c.CustomerID
    LEFT JOIN Users u ON i.UserID = u.UserID;
END;
GO

-- OrderDetails
CREATE TABLE OrderDetails (
    OrderDetailsID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
	ProductCode NVARCHAR(20) NULL,
	ProductName NVARCHAR(100) NULL,
    Quantity INT NOT NULL, -- Số lượng mua
    UnitPrice DECIMAL(18,2) NOT NULL, -- Giá tại thời điểm mua
    TotalPrice AS (Quantity * UnitPrice) PERSISTED
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE
);
GO

UPDATE od
SET 
    od.ProductCode = p.ProductCode,
    od.ProductName = p.ProductName
FROM OrderDetails od
JOIN Products p ON od.ProductID = p.ProductID
WHERE od.ProductCode IS NULL OR od.ProductName IS NULL;




GO
CREATE TRIGGER trg_UpdateProductCode
ON OrderDetails
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE od
    SET 
    od.ProductCode = p.ProductCode,
    od.ProductName = p.ProductName,
	od.UnitPrice = p.Price
    FROM OrderDetails od
    JOIN inserted i ON od.OrderDetailsID = i.OrderDetailsID
    JOIN Products p ON i.ProductID = p.ProductID;
END;
GO



-- Inventory Table
CREATE TABLE Inventory (
    InventoryID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    ProductCode NVARCHAR(20) NULL, 
    ProductName NVARCHAR(100) NULL,
    QuantityChange INT NOT NULL,
    ChangeType NVARCHAR(10) CHECK (ChangeType IN ('Import', 'Export')),
    ChangedBy INT NULL,
    UserCode NVARCHAR(20) NULL, 
    FullName NVARCHAR(100) NULL,
    LastUpdated DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    FOREIGN KEY (ChangedBy) REFERENCES Users(UserID)
);
GO

-- Trigger cập nhật tồn kho
CREATE TRIGGER trg_UpdateStock
ON Inventory
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xuất kho có vượt quá tồn kho hay không
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN Products p ON i.ProductID = p.ProductID
        WHERE i.ChangeType = 'Export' AND i.QuantityChange > p.Stock
    )
    BEGIN
        THROW 50000, 'Số lượng xuất kho vượt quá số lượng tồn!', 1;
        RETURN;
    END;

    -- Cập nhật tồn kho
    UPDATE p
    SET p.Stock = 
        CASE 
            WHEN i.ChangeType = 'Import' THEN p.Stock + i.QuantityChange
            WHEN i.ChangeType = 'Export' THEN p.Stock - i.QuantityChange
        END
    FROM Products p
    JOIN inserted i ON p.ProductID = i.ProductID;
END;
GO

-- Cập nhật thông tin sản phẩm và nhân viên vào Inventory
UPDATE t
SET 
    t.ProductCode = p.ProductCode,
    t.ProductName = p.ProductName,
    t.UserCode = u.UserCode,
    t.FullName = u.FullName
FROM Inventory t
JOIN Products p ON t.ProductID = p.ProductID
LEFT JOIN Users u ON t.ChangedBy = u.UserID
WHERE t.ProductCode IS NULL OR t.ProductName IS NULL OR t.UserCode IS NULL OR t.FullName IS NULL;
GO

-- Trigger cập nhật thông tin từ Products và Users vào Inventory khi có đơn hàng mới
CREATE TRIGGER trg_ProductUser
ON Inventory
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE t
    SET 
        t.ProductCode = p.ProductCode,
        t.ProductName = p.ProductName,
        t.UserCode = u.UserCode,
        t.FullName = u.FullName
    FROM Inventory t
    JOIN inserted i ON t.InventoryID = i.InventoryID
    LEFT JOIN Products p ON t.ProductID = p.ProductID
    LEFT JOIN Users u ON t.ChangedBy = u.UserID;
END;
GO


-- Expenses
CREATE TABLE Expenses (
    ExpenseID INT IDENTITY(1,1) PRIMARY KEY,
	ExpenseType NVARCHAR(100) NOT NULL, -- Loại chi tiêu
	Amount DECIMAL(18,2) NOT NULL, -- Số tiền chi tiêu
    ExpenseDate DATE NOT NULL,
    Notes NVARCHAR(255),
	UserID INT NULL, -- nếu có liên quan tới nhân viên nào
    OrderID INT NULL, -- nếu liên quan tới đơn hàng cụ thể
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);
GO

-- Tạo VIEW Revenue thay thế bảng Revenue

-- theo ngày
CREATE VIEW Revenue_View AS
SELECT 
    CAST(OrderDate AS DATE) AS Date, -- Lấy ngày từ OrderDate
    COUNT(OrderID) AS TotalOrders, -- Đếm số đơn hàng
    SUM(TotalPrice) AS TotalSales, -- Tổng doanh thu
    (COALESCE(SUM(TotalPrice), 0) - 
        COALESCE((SELECT SUM(Amount) 
                  FROM Expenses 
                  WHERE ExpenseDate = CAST(Orders.OrderDate AS DATE)), 0)) AS TotalProfit -- Lợi nhuận
FROM Orders
WHERE PaymentStatus = 'Completed' -- Chỉ tính đơn hàng hoàn thành
GROUP BY CAST(OrderDate AS DATE);
GO

-- theo tháng
CREATE VIEW Monthly_Revenue AS
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    COUNT(OrderID) AS TotalOrders, -- Số đơn hàng trong tháng
    SUM(TotalPrice) AS TotalSales -- Tổng doanh thu trong tháng
FROM Orders
WHERE PaymentStatus = 'Completed'
GROUP BY YEAR(OrderDate), MONTH(OrderDate);
GO

CREATE PROCEDURE Update_Profit_Report
AS
BEGIN
    SET NOCOUNT ON;

    -- Xóa dữ liệu cũ trước khi cập nhật
    DELETE FROM Profit_Report;

    -- Chèn dữ liệu mới từ Monthly_Revenue và Expenses
    INSERT INTO Profit_Report (Month, Year, TotalRevenue, TotalExpenses)
    SELECT 
        r.Month, r.Year,
        COALESCE(r.TotalSales, 0) AS TotalRevenue,
        COALESCE(e.TotalExpenses, 0) AS TotalExpenses
    FROM Monthly_Revenue r
    LEFT JOIN 
        (SELECT 
            YEAR(ExpenseDate) AS Year, 
            MONTH(ExpenseDate) AS Month, 
            SUM(Amount) AS TotalExpenses
         FROM Expenses
         GROUP BY YEAR(ExpenseDate), MONTH(ExpenseDate)) e
    ON r.Year = e.Year AND r.Month = e.Month;
END;
GO


-- Profit_Report
CREATE TABLE Profit_Report (
    ReportID INT IDENTITY(1,1) PRIMARY KEY,
    Month INT NOT NULL CHECK (Month BETWEEN 1 AND 12),
    Year INT NOT NULL,
    TotalRevenue DECIMAL(18,2) NOT NULL DEFAULT 0,
    TotalExpenses DECIMAL(18,2) NOT NULL DEFAULT 0,
    NetProfit AS (TotalRevenue - TotalExpenses) PERSISTED -- Cột tính toán tự động
);
GO

ALTER TABLE Profit_Report ADD CONSTRAINT UQ_Month_Year UNIQUE (Month, Year);
GO

EXEC Update_Profit_Report;
GO

-- Truy vấn dữ liệu từ các bảng
SELECT * FROM Users;
SELECT * FROM Roles;
SELECT * FROM Customers;
SELECT * FROM Products;
SELECT * FROM Categories;
SELECT * FROM Suppliers;
SELECT * FROM Orders;
SELECT * FROM OrderDetails;
SELECT * FROM Inventory;
SELECT * FROM Revenue_View; -- Xem doanh thu theo ngày
SELECT * FROM Monthly_Revenue; -- Xem doanh thu theo tháng
SELECT * FROM Expenses;
SELECT * FROM Profit_Report;
