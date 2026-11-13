-- =====================================================================
-- SAMPLE27 - XML schema repository (4 schemas)
--
-- Copyright (c) 2026 Marcin Paluch. All rights reserved.
--
-- The original SAMPLE has four XML schemas registered in the XML schema repository
-- (DB2INST1.CUSTOMER, PORDER, PRODUCT, SUPPLIER).  The exported DDL does not contain them, so a
-- rebuilt database had none, and XML samples such as sqllib/samples/xml/clp/xmlinsert.db2 failed
-- (SQL0204N on the schema CUSTOMER).  The four .xsd files ship with Db2 in
-- <Db2 install path>/samples/db2sampl.  Same names, same target namespace (http://posample.org).
-- @DB2PATH@ is the Db2 install path (db2level: "Product is installed at"); scripts/build_db.sh substitutes it.
-- To run this file by hand, replace @DB2PATH@ yourself first.
-- =====================================================================

CONNECT TO SAMPLE27;

REGISTER XMLSCHEMA 'http://posample.org' FROM '@DB2PATH@/samples/db2sampl/customer.xsd' AS DB2INST1.CUSTOMER COMPLETE;
REGISTER XMLSCHEMA 'http://posample.org' FROM '@DB2PATH@/samples/db2sampl/porder.xsd'   AS DB2INST1.PORDER COMPLETE;
REGISTER XMLSCHEMA 'http://posample.org' FROM '@DB2PATH@/samples/db2sampl/product.xsd'  AS DB2INST1.PRODUCT COMPLETE;
REGISTER XMLSCHEMA 'http://posample.org' FROM '@DB2PATH@/samples/db2sampl/supplier.xsd' AS DB2INST1.SUPPLIER COMPLETE;

CONNECT RESET;
