
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS "timescaledb" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";

CREATE SCHEMA IF NOT EXISTS "public";

ALTER SCHEMA "public" OWNER TO "pg_database_owner";

COMMENT ON SCHEMA "public" IS 'standard public schema';

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgtap" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "postgis" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";

CREATE EXTENSION IF NOT EXISTS "tcn" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

CREATE TYPE "public"."bill_of_lading_status" AS ENUM (
    'In Progress',
    'Paid',
    'Cancelled',
    'Received'
);

ALTER TYPE "public"."bill_of_lading_status" OWNER TO "postgres";

CREATE TYPE "public"."entity_type" AS ENUM (
    'Farmer',
    'Distributor',
    'Aggregator',
    'Food Hub',
    'Food Bank',
    'Hot / Cold Storage',
    'Final Recipient'
);

ALTER TYPE "public"."entity_type" OWNER TO "postgres";

CREATE TYPE "public"."order_delivery_status" AS ENUM (
    'Pending',
    'In Progress',
    'Completed',
    'Cancelled'
);

ALTER TYPE "public"."order_delivery_status" OWNER TO "postgres";

CREATE TYPE "public"."region_enum" AS ENUM (
    'Northwest',
    'Northeast',
    'Central',
    'Southwest',
    'Southeast'
);

ALTER TYPE "public"."region_enum" OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."notify_bill_of_lading_paid"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Check if marked_paid is set to true during update
  IF NEW.marked_paid IS TRUE AND OLD.marked_paid IS NOT TRUE THEN
    PERFORM supabase.edge_functions.invoke('yourEdgeFunctionNameForPaidStatus', json_build_object('newRecord', NEW, 'oldRecord', OLD));
  END IF;
  RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."notify_bill_of_lading_paid"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."notify_bill_of_lading_paid_and_create_delivery"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Check if marked_paid is set to true during update
  IF NEW.marked_paid IS TRUE AND OLD.marked_paid IS NOT TRUE THEN
    -- Optionally, invoke an Edge Function to send a notification/email
    -- PERFORM supabase.edge_functions.invoke('yourEdgeFunctionNameForPaidStatus', json_build_object('newRecord', NEW, 'oldRecord', OLD));

    -- Insert a new delivery record
    INSERT INTO public.delivery (bol_id, sender, recipient, transporter, status)
    VALUES (NEW.id, NEW.sender, NEW.recipient, NEW.transporter, 'In Progress');
  END IF;
  RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."notify_bill_of_lading_paid_and_create_delivery"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."notify_bill_of_lading_received"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Check if marked_received is set to true during update
  IF NEW.marked_received IS TRUE AND OLD.marked_received IS NOT TRUE THEN
    PERFORM supabase.edge_functions.invoke('yourEdgeFunctionNameHere', json_build_object('newRecord', NEW, 'oldRecord', OLD));
  END IF;
  RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."notify_bill_of_lading_received"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."notify_send_bill_of_lading"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  PERFORM supabase.edge_functions.invoke('sendEmailOnBillOfLadingSend', json_build_object('newRecord', NEW));
  RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."notify_send_bill_of_lading"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."update_user"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Check if user_id already exists in the users table
    IF EXISTS (SELECT 1 FROM users WHERE user_id = NEW.user_id) THEN
        -- Perform an update if it exists
        UPDATE users
        SET email = NEW.email,
            display_name = NEW.display_name,
            business_name = NEW.business_name,
            photo_url = NEW.photo_url
        WHERE user_id = NEW.user_id;
    ELSE
        -- Perform an insert if it does not exist
        INSERT INTO users(user_id, email, display_name, business_name, photo_url)
        VALUES (NEW.user_id, NEW.email, NEW.display_name, NEW.business_name, NEW.photo_url);
    END IF;
    RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."update_user"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."update_users_from_profile"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$BEGIN
    -- Check if user_id already exists in the users table
    IF EXISTS (SELECT 1 FROM users WHERE user_id = NEW.user_id) THEN
        -- Perform an update if it exists
        UPDATE users
        SET email = NEW.email,
            display_name = NEW.display_name,
            business_name = NEW.business_name,
            photo_url = NEW.photo_url
        WHERE user_id = NEW.user_id;
    ELSE
        -- Perform an insert if it does not exist
        INSERT INTO users(user_id, email, display_name, business_name, photo_url)
        VALUES (NEW.user_id, NEW.email, NEW.display_name, NEW.business_name, NEW.photo_url);
    END IF;
    RETURN NEW;
END;$$;

ALTER FUNCTION "public"."update_users_from_profile"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."bill_of_lading" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "transporter" "text",
    "status" "public"."bill_of_lading_status",
    "sender" "text",
    "recipient" "text",
    "marked_paid" boolean,
    "marked_received" boolean,
    "products" "text"[],
    "invoice_url" "text",
    "user_id" "uuid"
);

ALTER TABLE "public"."bill_of_lading" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."bol_products" (
    "id" bigint NOT NULL,
    "quantity" integer,
    "weight" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "title" "text",
    "bol_id" bigint NOT NULL
);

ALTER TABLE "public"."bol_products" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."in_counties" (
    "county_id" integer NOT NULL,
    "county_name" character varying(255) NOT NULL,
    "region_id" integer
);

ALTER TABLE "public"."in_counties" OWNER TO "postgres";

CREATE SEQUENCE IF NOT EXISTS "public"."counties_county_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "public"."counties_county_id_seq" OWNER TO "postgres";

ALTER SEQUENCE "public"."counties_county_id_seq" OWNED BY "public"."in_counties"."county_id";

CREATE TABLE IF NOT EXISTS "public"."cs_blk_loam" (
    "id" "uuid" NOT NULL,
    "occupation" "text"[],
    "farmer_spec" "text"[],
    "publications" "text"[],
    "events_resources" "text"[],
    "additional_notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."cs_blk_loam" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."cs_distribution" (
    "id" "uuid" NOT NULL,
    "transport_method" "text"[],
    "wholesale_partner" "text",
    "post_harvest_handling" "text"[],
    "product_assistance" "text"[],
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."cs_distribution" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."cs_farm_product" (
    "id" "uuid" NOT NULL,
    "products_offered" "text"[],
    "farming_years_exp" "text",
    "production_duration" "text",
    "market_locations" "text"[],
    "program_quantity" "text",
    "farming_status" "text",
    "certifications" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."cs_farm_product" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."cs_fsnc" (
    "id" "uuid" NOT NULL,
    "existing_program" "text",
    "network_connections" "text",
    "has_donated" boolean,
    "has_sold" boolean,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."cs_fsnc" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."cs_impact" (
    "id" "uuid" NOT NULL,
    "participation" "text"[],
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "impact_score" "text"
);

ALTER TABLE "public"."cs_impact" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."cs_sdhu" (
    "id" "uuid" NOT NULL,
    "ethnicity" "text",
    "is_bipoc" boolean,
    "is_sd" boolean,
    "is_hu" boolean,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."cs_sdhu" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."cs_tech_assist" (
    "id" "uuid" NOT NULL,
    "technical_assist" "text"[],
    "other" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."cs_tech_assist" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."delivery" (
    "delivery_id" bigint NOT NULL,
    "sender" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "bol_id" bigint,
    "transporter" "text",
    "final_recipient" "text",
    "signature_image" "text",
    "product_image" "text",
    "recipient" "text",
    "status" "public"."order_delivery_status",
    "user_id" "uuid",
    "region" "public"."region_enum",
    "county" "text",
    CONSTRAINT "delivery_sender_check" CHECK (("length"("sender") < 500))
);

ALTER TABLE "public"."delivery" OWNER TO "postgres";

ALTER TABLE "public"."delivery" ALTER COLUMN "delivery_id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."delivery_delivery_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

ALTER TABLE "public"."bol_products" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."invoice_products_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

ALTER TABLE "public"."bol_products" ALTER COLUMN "bol_id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."invoice_products_invoice_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

ALTER TABLE "public"."bill_of_lading" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."invoices_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."profile" (
    "user_id" "uuid" NOT NULL,
    "email" character varying NOT NULL,
    "phone_number" "text" NOT NULL,
    "first_name" "text",
    "last_name" "text",
    "display_name" "text",
    "business_name" "text",
    "business_address" "text",
    "county" "text",
    "photo_url" "text",
    "region" "public"."region_enum",
    "best_contact_form" "text",
    "best_contact_time" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "address" "text",
    "address_optional" "text",
    "city" "text",
    "state" "text",
    "zip_code" "text",
    "entity" "public"."entity_type"[]
);

ALTER TABLE "public"."profile" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."regions" (
    "region_id" integer NOT NULL,
    "region_name" "public"."region_enum" NOT NULL
);

ALTER TABLE "public"."regions" OWNER TO "postgres";

CREATE SEQUENCE IF NOT EXISTS "public"."regions_region_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "public"."regions_region_id_seq" OWNER TO "postgres";

ALTER SEQUENCE "public"."regions_region_id_seq" OWNED BY "public"."regions"."region_id";

CREATE TABLE IF NOT EXISTS "public"."users" (
    "user_id" "uuid" NOT NULL,
    "email" character varying NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "display_name" "text",
    "business_name" "text",
    "photo_url" "text",
    "has_admin_access" boolean DEFAULT false
);

ALTER TABLE "public"."users" OWNER TO "postgres";

ALTER TABLE ONLY "public"."in_counties" ALTER COLUMN "county_id" SET DEFAULT "nextval"('"public"."counties_county_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."regions" ALTER COLUMN "region_id" SET DEFAULT "nextval"('"public"."regions_region_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."in_counties"
    ADD CONSTRAINT "counties_pkey" PRIMARY KEY ("county_id");

ALTER TABLE ONLY "public"."cs_blk_loam"
    ADD CONSTRAINT "cs_blk_loam_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cs_distribution"
    ADD CONSTRAINT "cs_distribution_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cs_farm_product"
    ADD CONSTRAINT "cs_farm_product_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cs_fsnc"
    ADD CONSTRAINT "cs_fsnc_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cs_impact"
    ADD CONSTRAINT "cs_impact_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cs_sdhu"
    ADD CONSTRAINT "cs_sdhu_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cs_tech_assist"
    ADD CONSTRAINT "cs_tech_assist_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."delivery"
    ADD CONSTRAINT "delivery_bol_id_key" UNIQUE ("bol_id");

ALTER TABLE ONLY "public"."delivery"
    ADD CONSTRAINT "delivery_pkey" PRIMARY KEY ("delivery_id");

ALTER TABLE ONLY "public"."bol_products"
    ADD CONSTRAINT "invoice_products_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."bill_of_lading"
    ADD CONSTRAINT "invoices_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."regions"
    ADD CONSTRAINT "regions_pkey" PRIMARY KEY ("region_id");

ALTER TABLE ONLY "public"."profile"
    ADD CONSTRAINT "user_profile_email_key" UNIQUE ("email");

ALTER TABLE ONLY "public"."profile"
    ADD CONSTRAINT "user_profile_pkey" PRIMARY KEY ("user_id");

ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("user_id", "email");

CREATE OR REPLACE TRIGGER "send_bill_of_lading_trigger" AFTER INSERT ON "public"."bill_of_lading" FOR EACH ROW EXECUTE FUNCTION "public"."notify_send_bill_of_lading"();

CREATE OR REPLACE TRIGGER "trigger_bill_of_lading_paid" AFTER UPDATE ON "public"."bill_of_lading" FOR EACH ROW WHEN ((("old"."marked_paid" IS NOT TRUE) AND ("new"."marked_paid" IS TRUE))) EXECUTE FUNCTION "public"."notify_bill_of_lading_paid"();

CREATE OR REPLACE TRIGGER "trigger_bill_of_lading_received" AFTER UPDATE ON "public"."bill_of_lading" FOR EACH ROW WHEN ((("old"."marked_received" IS NOT TRUE) AND ("new"."marked_received" IS TRUE))) EXECUTE FUNCTION "public"."notify_bill_of_lading_received"();

CREATE OR REPLACE TRIGGER "trigger_update_users_from_profile" AFTER INSERT OR UPDATE ON "public"."profile" FOR EACH ROW EXECUTE FUNCTION "public"."update_users_from_profile"();

ALTER TABLE "public"."profile" ENABLE ALWAYS TRIGGER "trigger_update_users_from_profile";

ALTER TABLE ONLY "public"."in_counties"
    ADD CONSTRAINT "counties_region_id_fkey" FOREIGN KEY ("region_id") REFERENCES "public"."regions"("region_id");

ALTER TABLE ONLY "public"."cs_blk_loam"
    ADD CONSTRAINT "public_cs_blk_loam_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."profile"("user_id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."cs_distribution"
    ADD CONSTRAINT "public_cs_distribution_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."profile"("user_id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."cs_farm_product"
    ADD CONSTRAINT "public_cs_farm_product_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."profile"("user_id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."cs_fsnc"
    ADD CONSTRAINT "public_cs_fsnc_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."profile"("user_id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."cs_impact"
    ADD CONSTRAINT "public_cs_impact_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."profile"("user_id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."cs_sdhu"
    ADD CONSTRAINT "public_cs_sdhu_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."profile"("user_id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."cs_tech_assist"
    ADD CONSTRAINT "public_cs_tech_assist_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."profile"("user_id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."delivery"
    ADD CONSTRAINT "public_delivery_invoice_id_fkey" FOREIGN KEY ("bol_id") REFERENCES "public"."bill_of_lading"("id");

ALTER TABLE ONLY "public"."bol_products"
    ADD CONSTRAINT "public_invoice_products_invoice_fkey" FOREIGN KEY ("bol_id") REFERENCES "public"."bill_of_lading"("id");

ALTER TABLE ONLY "public"."profile"
    ADD CONSTRAINT "public_profile_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "public_users_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;

CREATE POLICY "Enable insert for authenticated users only" ON "public"."bill_of_lading" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."bol_products" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."profile" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for users based on user_id" ON "public"."cs_blk_loam" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."cs_distribution" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."cs_farm_product" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."cs_fsnc" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."cs_impact" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."cs_sdhu" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."cs_tech_assist" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."delivery" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."users" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));

CREATE POLICY "Enable read access for all users" ON "public"."bill_of_lading" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."bol_products" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."cs_blk_loam" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."cs_distribution" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."cs_farm_product" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."cs_fsnc" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."cs_impact" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."cs_sdhu" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."cs_tech_assist" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."delivery" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."in_counties" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."profile" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."regions" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."users" FOR SELECT USING (true);

CREATE POLICY "Enable update for users based on email" ON "public"."users" FOR UPDATE USING ((("auth"."jwt"() ->> 'email'::"text") = ("email")::"text")) WITH CHECK ((("auth"."jwt"() ->> 'email'::"text") = ("email")::"text"));

ALTER TABLE "public"."bill_of_lading" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."bol_products" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cs_blk_loam" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cs_distribution" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cs_farm_product" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cs_fsnc" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cs_impact" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cs_sdhu" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cs_tech_assist" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."delivery" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."in_counties" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."profile" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."regions" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."notify_bill_of_lading_paid"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_bill_of_lading_paid"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_bill_of_lading_paid"() TO "service_role";

GRANT ALL ON FUNCTION "public"."notify_bill_of_lading_paid_and_create_delivery"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_bill_of_lading_paid_and_create_delivery"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_bill_of_lading_paid_and_create_delivery"() TO "service_role";

GRANT ALL ON FUNCTION "public"."notify_bill_of_lading_received"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_bill_of_lading_received"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_bill_of_lading_received"() TO "service_role";

GRANT ALL ON FUNCTION "public"."notify_send_bill_of_lading"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_send_bill_of_lading"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_send_bill_of_lading"() TO "service_role";

GRANT ALL ON FUNCTION "public"."update_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_user"() TO "service_role";

GRANT ALL ON FUNCTION "public"."update_users_from_profile"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_users_from_profile"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_users_from_profile"() TO "service_role";

GRANT ALL ON TABLE "public"."bill_of_lading" TO "anon";
GRANT ALL ON TABLE "public"."bill_of_lading" TO "authenticated";
GRANT ALL ON TABLE "public"."bill_of_lading" TO "service_role";

GRANT ALL ON TABLE "public"."bol_products" TO "anon";
GRANT ALL ON TABLE "public"."bol_products" TO "authenticated";
GRANT ALL ON TABLE "public"."bol_products" TO "service_role";

GRANT ALL ON TABLE "public"."in_counties" TO "anon";
GRANT ALL ON TABLE "public"."in_counties" TO "authenticated";
GRANT ALL ON TABLE "public"."in_counties" TO "service_role";

GRANT ALL ON SEQUENCE "public"."counties_county_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."counties_county_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."counties_county_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."cs_blk_loam" TO "anon";
GRANT ALL ON TABLE "public"."cs_blk_loam" TO "authenticated";
GRANT ALL ON TABLE "public"."cs_blk_loam" TO "service_role";

GRANT ALL ON TABLE "public"."cs_distribution" TO "anon";
GRANT ALL ON TABLE "public"."cs_distribution" TO "authenticated";
GRANT ALL ON TABLE "public"."cs_distribution" TO "service_role";

GRANT ALL ON TABLE "public"."cs_farm_product" TO "anon";
GRANT ALL ON TABLE "public"."cs_farm_product" TO "authenticated";
GRANT ALL ON TABLE "public"."cs_farm_product" TO "service_role";

GRANT ALL ON TABLE "public"."cs_fsnc" TO "anon";
GRANT ALL ON TABLE "public"."cs_fsnc" TO "authenticated";
GRANT ALL ON TABLE "public"."cs_fsnc" TO "service_role";

GRANT ALL ON TABLE "public"."cs_impact" TO "anon";
GRANT ALL ON TABLE "public"."cs_impact" TO "authenticated";
GRANT ALL ON TABLE "public"."cs_impact" TO "service_role";

GRANT ALL ON TABLE "public"."cs_sdhu" TO "anon";
GRANT ALL ON TABLE "public"."cs_sdhu" TO "authenticated";
GRANT ALL ON TABLE "public"."cs_sdhu" TO "service_role";

GRANT ALL ON TABLE "public"."cs_tech_assist" TO "anon";
GRANT ALL ON TABLE "public"."cs_tech_assist" TO "authenticated";
GRANT ALL ON TABLE "public"."cs_tech_assist" TO "service_role";

GRANT ALL ON TABLE "public"."delivery" TO "anon";
GRANT ALL ON TABLE "public"."delivery" TO "authenticated";
GRANT ALL ON TABLE "public"."delivery" TO "service_role";

GRANT ALL ON SEQUENCE "public"."delivery_delivery_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."delivery_delivery_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."delivery_delivery_id_seq" TO "service_role";

GRANT ALL ON SEQUENCE "public"."invoice_products_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."invoice_products_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."invoice_products_id_seq" TO "service_role";

GRANT ALL ON SEQUENCE "public"."invoice_products_invoice_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."invoice_products_invoice_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."invoice_products_invoice_seq" TO "service_role";

GRANT ALL ON SEQUENCE "public"."invoices_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."invoices_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."invoices_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."profile" TO "anon";
GRANT ALL ON TABLE "public"."profile" TO "authenticated";
GRANT ALL ON TABLE "public"."profile" TO "service_role";

GRANT ALL ON TABLE "public"."regions" TO "anon";
GRANT ALL ON TABLE "public"."regions" TO "authenticated";
GRANT ALL ON TABLE "public"."regions" TO "service_role";

GRANT ALL ON SEQUENCE "public"."regions_region_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."regions_region_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."regions_region_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;
