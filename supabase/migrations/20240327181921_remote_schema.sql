
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

CREATE OR REPLACE FUNCTION "public"."update_users_table_on_signup"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
    INSERT INTO users (user_id, email, display_name, business_name, photo_url)
    VALUES (NEW.user_id, NEW.email, NEW.display_name, NEW.business_name, NEW.photo_url);
    RETURN NEW;
END;$$;

ALTER FUNCTION "public"."update_users_table_on_signup"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."bill_of_lading" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "transporter" "text",
    "status" "text",
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
    "transport_method" "text",
    "wholesale_partner" "text",
    "post_harvest_handling" "text",
    "product_assistance" "text"[],
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."cs_distribution" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."cs_farm_product" (
    "id" "uuid" NOT NULL,
    "products_offered" "text",
    "farming_years_exp" "text",
    "production_duration" "text",
    "market_locations" "text",
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
    "participation" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
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
    "status" "text",
    "user_id" "uuid",
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
    "region" "text",
    "best_contact_form" "text",
    "best_contact_time" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "address" "text",
    "address_optional" "text",
    "city" "text",
    "state" "text",
    "zip_code" "text",
    "entity" "text"[]
);

ALTER TABLE "public"."profile" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."users" (
    "user_id" "uuid" NOT NULL,
    "email" character varying NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "has_admin_access" boolean DEFAULT false,
    "display_name" "text",
    "business_name" "text",
    "photo_url" "text"
);

ALTER TABLE "public"."users" OWNER TO "postgres";

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

ALTER TABLE ONLY "public"."profile"
    ADD CONSTRAINT "user_profile_email_key" UNIQUE ("email");

ALTER TABLE ONLY "public"."profile"
    ADD CONSTRAINT "user_profile_phone_number_key" UNIQUE ("phone_number");

ALTER TABLE ONLY "public"."profile"
    ADD CONSTRAINT "user_profile_pkey" PRIMARY KEY ("user_id");

ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("user_id", "email");

CREATE OR REPLACE TRIGGER "update_users_table" AFTER INSERT OR DELETE OR UPDATE ON "public"."profile" FOR EACH STATEMENT EXECUTE FUNCTION "public"."update_users_table_on_signup"();

ALTER TABLE "public"."profile" ENABLE REPLICA TRIGGER "update_users_table";

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
    ADD CONSTRAINT "public_cs_tech_assist_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."profile"("user_id");

ALTER TABLE ONLY "public"."delivery"
    ADD CONSTRAINT "public_delivery_invoice_id_fkey" FOREIGN KEY ("bol_id") REFERENCES "public"."bill_of_lading"("id");

ALTER TABLE ONLY "public"."bol_products"
    ADD CONSTRAINT "public_invoice_products_invoice_fkey" FOREIGN KEY ("bol_id") REFERENCES "public"."bill_of_lading"("id");

ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "public_users_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;

CREATE POLICY "Enable insert for authenticated users only" ON "public"."bol_products" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for users based on user_id" ON "public"."bill_of_lading" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."cs_blk_loam" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."cs_distribution" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."cs_farm_product" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."cs_fsnc" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."cs_impact" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."cs_sdhu" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."cs_tech_assist" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."delivery" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."profile" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));

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

CREATE POLICY "Enable read access for all users" ON "public"."profile" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."users" FOR SELECT USING (true);

CREATE POLICY "Enable update for users based on email" ON "public"."profile" FOR UPDATE USING ((("auth"."jwt"() ->> 'email'::"text") = ("email")::"text")) WITH CHECK ((("auth"."jwt"() ->> 'email'::"text") = ("email")::"text"));

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

ALTER TABLE "public"."profile" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."update_users_table_on_signup"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_users_table_on_signup"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_users_table_on_signup"() TO "service_role";

GRANT ALL ON TABLE "public"."bill_of_lading" TO "anon";
GRANT ALL ON TABLE "public"."bill_of_lading" TO "authenticated";
GRANT ALL ON TABLE "public"."bill_of_lading" TO "service_role";

GRANT ALL ON TABLE "public"."bol_products" TO "anon";
GRANT ALL ON TABLE "public"."bol_products" TO "authenticated";
GRANT ALL ON TABLE "public"."bol_products" TO "service_role";

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
