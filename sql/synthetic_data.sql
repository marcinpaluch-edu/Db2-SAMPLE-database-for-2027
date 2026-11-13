-- =====================================================================
-- SAMPLE27 - synthetic data (permanent part of the build)
-- Copyright (c) 2026 Marcin Paluch. All rights reserved.
--
-- Run by build_db.sh after data_fixes.sql.  These rows do not exist in the
-- original SAMPLE.  They are added so that every foreign key SAMPLE27 added has real parent AND
-- child rows to be tested with, and so that SAMPSEQUENCE is actually used.
--
--   FK_EMPPROJACT_EMP  EMPPROJACT.EMPNO -> EMPLOYEE   3 employees who had no assignment now have one
--                                                      (ORLANDO 200120, YAMAMOTO 200170, JOHN 200220;
--                                                       work inside the project PL2100; their hire dates move back by
--                                                       whole years, the same rule as in data_fixes.sql)
--   RPAA               PROJACT.ACTNO -> ACT           activity 120 (STAFF), unused in the original
--   FK_INVENTORY_PROD  INVENTORY.PID -> PRODUCT       2 new products with stock
--   FK_PRODSUPP_PROD   PRODUCTSUPPLIER.PID -> PRODUCT  4 new product/supplier pairs
--   FK_PRODSUPP_SUPP   PRODUCTSUPPLIER.SID -> SUPPLIERS 1 new supplier (102), a product with two suppliers
--   SAMPSEQUENCE       PURCHASEORDER.POID             2 new orders, POID taken from the sequence
--                                                      (the sequence starts at 5007, above the 5000-5006 loaded)
--
-- The leavers (O'CONNELL, SCHWARTZ, SPRINGER, NATZ, MONTEVERDE, WONG, ALONZO)
-- are deliberately not given assignments.
-- =====================================================================

CONNECT TO SAMPLE27;

-- project work for employees who had none (PL2100 runs 2002-01-01 .. 2002-09-15) -----------------
INSERT INTO DB2INST1.PROJACT (PROJNO, ACTNO, ACSTAFF, ACSTDATE, ACENDATE)
  VALUES ('PL2100', 120, 1.50, '2002-03-01', '2002-08-31');

INSERT INTO DB2INST1.EMPPROJACT (EMPNO, PROJNO, ACTNO, EMPTIME, EMSTDATE, EMENDATE) VALUES
  ('200120', 'PL2100', 120, 0.50, '2002-03-01', '2002-08-31'),
  ('200170', 'PL2100', 120, 0.50, '2002-03-01', '2002-06-30'),
  ('200220', 'PL2100', 120, 0.50, '2002-03-01', '2002-08-31');

-- same rule as data_fixes.sql step 2: nobody works before being hired (whole years back, month and day kept)
UPDATE DB2INST1.EMPLOYEE E
   SET HIREDATE = HIREDATE - ((YEAR(HIREDATE) - (SELECT YEAR(MIN(P.EMSTDATE)) FROM DB2INST1.EMPPROJACT P WHERE P.EMPNO = E.EMPNO))
                              + CASE WHEN MONTH(HIREDATE) * 100 + DAY(HIREDATE)
                                         > (SELECT MONTH(MIN(P.EMSTDATE)) * 100 + DAY(MIN(P.EMSTDATE)) FROM DB2INST1.EMPPROJACT P WHERE P.EMPNO = E.EMPNO)
                                     THEN 1 ELSE 0 END) YEARS
 WHERE HIREDATE > (SELECT MIN(P.EMSTDATE) FROM DB2INST1.EMPPROJACT P WHERE P.EMPNO = E.EMPNO);

-- two new products, their stock, a new supplier and the product/supplier links ---------------------
INSERT INTO DB2INST1.PRODUCT (PID, NAME, PRICE, PROMOPRICE, PROMOSTART, PROMOEND, DESCRIPTION) VALUES
  ('100-110-01', 'Snow Shovel, Ergonomic 25 inch', 29.99, 24.99, '2005-10-01', '2005-11-01',
   XMLPARSE(DOCUMENT '<product pid="100-110-01"><description><name>Snow Shovel, Ergonomic 25 inch</name><details>Ergonomic Snow Shovel, 25 inches wide, bent handle with D-Grip</details><price>29.99</price><weight>1.4 kg</weight></description></product>' PRESERVE WHITESPACE)),
  ('100-202-01', 'Ice Scraper, Extendable 20 inch', 7.99, NULL, NULL, NULL,
   XMLPARSE(DOCUMENT '<product pid="100-202-01"><description><name>Ice Scraper, Extendable 20 inch</name><details>Extendable Ice Scraper with brush, 20 inches long</details><price>7.99</price><weight>0.3 kg</weight></description></product>' PRESERVE WHITESPACE));

INSERT INTO DB2INST1.INVENTORY (PID, QUANTITY, LOCATION) VALUES
  ('100-110-01', 40, 'Warehouse'),
  ('100-202-01', 120, 'Store');

INSERT INTO DB2INST1.SUPPLIERS (SID, ADDR) VALUES
  ('102', XMLPARSE(DOCUMENT '<supplierinfo xmlns="http://posample.org" Sid="102"><name>Northern Tools Ltd</name><addr country="Canada"><street>12 Bank Street</street><city>Ottawa</city><prov-state>Ontario</prov-state><pcode-zip>K1P 5N2</pcode-zip></addr></supplierinfo>' PRESERVE WHITESPACE));

INSERT INTO DB2INST1.PRODUCTSUPPLIER (PID, SID) VALUES
  ('100-110-01', '101'),
  ('100-110-01', '102'),
  ('100-202-01', '100'),
  ('100-103-01', '102');

-- purchase orders numbered by SAMPSEQUENCE ---------------------------------------------------------
-- NEXT VALUE FOR gives the same value everywhere it appears in one statement, so the key and the
-- PoNum attribute inside the XML document agree.
INSERT INTO DB2INST1.PURCHASEORDER (POID, STATUS, CUSTID, ORDERDATE, PORDER, COMMENTS)
  VALUES (NEXT VALUE FOR DB2INST1.SAMPSEQUENCE, 'Unshipped', 1003, '2006-03-10',
          XMLPARSE(DOCUMENT '<PurchaseOrder PoNum="' || RTRIM(CHAR(NEXT VALUE FOR DB2INST1.SAMPSEQUENCE)) || '" OrderDate="2006-03-10" Status="Unshipped"><item><partid>100-110-01</partid><name>Snow Shovel, Ergonomic 25 inch</name><quantity>2</quantity><price>29.99</price></item><item><partid>100-202-01</partid><name>Ice Scraper, Extendable 20 inch</name><quantity>4</quantity><price>7.99</price></item></PurchaseOrder>' PRESERVE WHITESPACE),
          'Synthetic order, POID from SAMPSEQUENCE');

INSERT INTO DB2INST1.PURCHASEORDER (POID, STATUS, CUSTID, ORDERDATE, PORDER, COMMENTS)
  VALUES (NEXT VALUE FOR DB2INST1.SAMPSEQUENCE, 'Shipped', 1001, '2006-04-02',
          XMLPARSE(DOCUMENT '<PurchaseOrder PoNum="' || RTRIM(CHAR(NEXT VALUE FOR DB2INST1.SAMPSEQUENCE)) || '" OrderDate="2006-04-02" Status="Shipped"><item><partid>100-101-01</partid><name>Snow Shovel, Deluxe 24 inch</name><quantity>1</quantity><price>19.99</price></item></PurchaseOrder>' PRESERVE WHITESPACE),
          'Synthetic order, POID from SAMPSEQUENCE');

COMMIT;

REFRESH TABLE DB2INST1.ADEFUSR;
COMMIT;

CONNECT RESET;
