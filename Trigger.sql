set serveroutput on;
--Các Trigger ràng buộc toàn vẹn (khóa ngoại, không trùng giá trị, ….)
--1.Cài đặt trigger tên sản phẩm không được trùng
CREATE OR REPLACE TRIGGER trg_insert_tensp
BEFORE INSERT ON SANPHAM
FOR EACH ROW
DECLARE
    v_count_masp int := 0;
    v_count_tensp int := 0;
BEGIN 
    SELECT COUNT(*)
    INTO v_count_tensp
    FROM SANPHAM
    WHERE TENSP = :NEW.TENSP;
    
    SELECT COUNT(*)
    INTO v_count_masp
    FROM SANPHAM
    WHERE MASP = :NEW.MASP;
    
    IF UPDATING THEN
        IF v_count_tensp > 0 THEN   
            raise_application_error(-20010, 'Đã tồn tại tên sản phẩm này. Xin vui lòng cập nhật tên khác');
        ELSIF v_count_masp = 0 THEN
            raise_application_error(-20010, 'Không tồn tại mã sản phẩm này. Xin vui lòng cập nhật mã sản phẩm khác');
        END IF;
    ELSIF INSERTING THEN 
        IF v_count_tensp > 0 THEN   
            raise_application_error(-20010, 'Đã tồn tại tên sản phẩm này. Xin vui lòng thêm sản phẩm khác');
        ELSIF v_count_masp > 0 THEN
            raise_application_error(-20010, 'Đã tồn tại mã sản phẩm này!!!');
        END IF;
    END IF;
END;

desc sanpham;
select * from sanpham order by masp desc;

delete sanpham
where masp = 'SP012';

--insert sai
insert into sanpham(masp, tensp)
values('SP010', 'Sofm');

insert into sanpham(masp, tensp)
values('SP012', 'Sofa Ruby');
--insert đúng
insert into sanpham(masp, tensp)
values('SP011', 'Sofa A');


--2/ Cài đặt trigger cho giá bán của sản phẩm không dược để trống và không đươc có giá là 0
CREATE OR REPLACE TRIGGER trg_insert_ktgia 
BEFORE INSERT OR UPDATE OF giaban
ON SANPHAM FOR EACH ROW
DECLARE
    v_giasp SANPHAM.giaban%TYPE;
BEGIN
    v_giasp := :new.giaban;
    IF v_giasp IS NULL or v_giasp = 0 THEN
        raise_application_error(-20010, 'Giá không được để trống và phải lớn hơn 0');
    ELSE
        dbms_output.put_line(v_giasp);
    END IF;
END;
 
 --test sai
 insert into SANPHAM(MASP,TENSP,GIABAN)
 values ('SP011', N'Cô Đơn Trên SoFa',0);
 
 insert into SANPHAM(MASP,TENSP,GIABAN)
 values ('SP011', N'Ghế Hoàng Đế',null);
  --test đúng
 insert into SANPHAM(MASP,TENSP,GIABAN)
 values ('SP012', N'Tủ quần áo inox cao cấp',1500000);




/*"Các Trigger bảo vệ dữ liệu 
- không cho phép cập nhật bảng trong khoảng thời gian quy định trong ngày
- Lưu History
- …"*/
--1. Chỉ cho update từ 8 giờ đến 17 giờ
CREATE OR REPLACE TRIGGER trg_khong_update_ngoai_gio
BEFORE UPDATE ON SANPHAM
DECLARE
    v_allowed_time_from DATE := TRUNC(SYSDATE) + INTERVAL '8' HOUR;
    v_allowed_time_to DATE := TRUNC(SYSDATE) + INTERVAL '17' HOUR;
BEGIN
    IF SYSDATE < v_allowed_time_from OR SYSDATE > v_allowed_time_to THEN
        raise_application_error(-20001, 'Không thể cập nhật dữ liệu trong khoảng thời gian này.');
    END IF;
END;

select * from sanpham order by masp desc;

--test update
update sanpham
set tensp = 'OK'
where masp = 'SP010';

--2. Lưu lịch sử thao tác. Tạo một bảng để lưu nhật ký thêm, sửa, xóa sản phẩm
create table SANPHAM_HISTORY(
    MASP CHAR(5),
    TENSP NVARCHAR2(100),
    THAOTAC NVARCHAR2(100),
    NGAYTHUCHIEN DATE
)

CREATE OR REPLACE TRIGGER trg_save_history
AFTER INSERT OR DELETE OR UPDATE ON SANPHAM
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(20);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
    ELSE
        v_operation := 'DELETE';
    END IF;

    -- Chèn cả MASP và TENSP vào bảng SANPHAM_HISTORY
    INSERT INTO SANPHAM_HISTORY (MASP, TENSP, THAOTAC, NGAYTHUCHIEN)
    VALUES (COALESCE(:NEW.MASP, :OLD.MASP), COALESCE(:NEW.TENSP, :OLD.TENSP), v_operation, SYSDATE);
END;

select * from sanpham order by masp desc;
select * from SANPHAM_HISTORY order by ngaythuchien desc;
desc sanpham_history;

delete sanpham
where masp = upper('sp011');

--insert
insert into SANPHAM(masp, tensp)
values('SP011', 'Sofa A');
--update
update sanpham
set tensp = 'con cò'
where masp = 'SP011';
--delete
delete sanpham
where masp ='SP011';
