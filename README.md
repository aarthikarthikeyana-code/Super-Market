# Agaram Supermarket

Flutter customer and store administration app backed by Django REST Framework, Neon PostgreSQL and Cloudinary, with cash-on-delivery ordering.

The app opens the customer store. **Staff login** offers separate administrator and delivery employee sign-in. Admins publish the same products customers browse; all ordering, prices, stock, payments and delivery progress come from the API. There is no runtime sample catalog, sample cart, fake order history, fake reviews, or screen-jump access to administration.

## Run the backend locally

Use Python 3.12 and a virtual environment. Copy `backend/.env.example` to `backend/.env` and configure it. Never commit `.env`.

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r backend/requirements.txt
.\.venv\Scripts\python.exe backend/manage.py migrate
.\.venv\Scripts\python.exe backend/manage.py bootstrap_admin
.\.venv\Scripts\python.exe backend/manage.py runserver
```

`bootstrap_admin` creates the initial staff user using `ADMIN_EMAIL` and `ADMIN_PASSWORD` from the environment. It does not reset existing accounts or accept demo credentials. Use Django password-management commands to rotate an existing account's password.

## Deploy the existing Render service

For **super-market-33m1.onrender.com**, set:

- Root directory: `backend`
- Build command: `bash build.sh`
- Start command: `bash start.sh`
- Health check: `/api/health/`
- Environment: copy the backend values from your local `.env` into Render's Environment settings, including the Neon `DATABASE_URL`, a long random `SECRET_KEY`, admin credentials and Cloudinary credentials. `DEBUG=false`.

`render.yaml` documents equivalent settings for a new service. Do not create a duplicate service just to update the existing one. The local `.env` is deliberately excluded from Git and will not automatically reach Render. The ignored `backend/render.env` file contains all current deployment values in a single copy-paste block; use Render **Environment > Add from .env** to import its complete contents. Startup applies migrations and creates the first administrator. No demo data is seeded.

The additive migrations leave existing prototype records in the database but unpublished/inactive. Customer APIs only expose published products and the signed-in customer's own orders. Publish new real products from the admin app. Demo seeding has been removed. Existing real legacy catalog records should be reviewed before republishing them through Django administration.

## Cash on delivery and order operations

New orders use cash on delivery only. There is no payment gateway, online payment SDK, or payment webhook. Remove old `RAZORPAY_*` and `PAYMENT_GATEWAY_ENABLED` variables from the Render environment; the application no longer reads them. The local `.env` and `render.env` have already been updated. Historical online payment reference columns remain in the database to preserve existing records.

Customers sign in, review their saved address and place an order without prepaying. The server calculates prices and delivery charges, reserves stock atomically, and uses an idempotency key to prevent duplicate orders on retries. Customers may cancel a new order before preparation begins; cancellation restores stock exactly once.

Administrators manage **New -> Preparing -> Packed -> Out for Delivery -> Delivered**. Dispatch requires an active delivery person. At delivery, the assigned employee enters the exact cash amount and confirms receipt from the customer; an administrator can also record this on the employee's behalf. Only then does the order become Delivered / Cash collected. The receipt records the amount, timestamp and staff user. The dashboard separately reports cash collected and cash still due; placing an order does not count as cash received.

An unsuccessful delivery becomes **Delivery Attempted** with a mandatory customer-visible reason. Staff can assign another person/arrival estimate and retry, or cancel after confirming the items have returned to store. Orders already out for delivery must first be marked attempted before cancellation; this prevents restoring stock that is still with a driver. Delivered orders cannot be cancelled or edited through this flow. Delivery notes, assigned contact, estimated arrival and the activity timeline appear in the customer app. Administrators manage preparation, assignments, cancellations and cash handovers. Delivery employees sign in separately to manage only their assigned work. There is no GPS tracking.

Existing unpaid online checkouts may still be cancelled or released by `python manage.py expire_checkouts`. Historical paid orders remain readable and are not converted into cash payments. Old payment disputes/refunds require manual review against the original provider's records.

## Delivery employee accounts and cash handovers

Open **Staff login > Admin login > Delivery team** to create or upgrade an employee. The server generates a `DEL...` employee ID and creates a non-admin user with a hashed password. Share the employee ID and the password you set directly with that employee. Employees use **Staff login > Delivery employee login**. Employee sessions stay in app memory; password resets and deactivation revoke their server tokens. Customers keep their separate mobile-number account flow.

The onboarding form records name, Indian mobile number, optional email, residential address/city/pincode, emergency contact name/mobile, joining date, delivery mode and account state. Motor vehicle delivery also requires vehicle registration number, driving licence number and expiry. Identity fields record an ID type and optional last four characters, not a full Aadhaar number. Admins record employee consent and confirm they checked the original identity and applicable vehicle documents. Uploading copies is optional for this manual original-document check; uploads alone do not verify anyone's identity. Changing onboarding identity/vehicle details through the API without explicit re-verification clears verification. Only active, verified employee accounts with a current licence where needed appear for assignment/dispatch. Legacy delivery-person records need onboarding and a password before receiving new assignments.

Document photo types are identity proof (masked Aadhaar or another ID), address proof, driving licence, vehicle RC, insurance and employee photograph. This is the application's practical onboarding checklist, not a statement that every document is universally required by law. Use only necessary records. The form does not request PAN, bank details or a full Aadhaar number. Motor vehicle document references: https://mparivahan.parivahan.gov.in/mstatic/english/ministry-advisory.html . Masked Aadhaar reference: https://uidai.gov.in/kn/aadhaar-online-services .

Document uploads accept JPEG/PNG/WebP photos up to 8 MB and use Cloudinary `authenticated` delivery, separate from public product images. Cloudinary must permit authenticated uploads. There is no public-upload fallback. Only administrators can upload, view or delete copies; view links are signed and expire after 60 seconds. A new/removed document copy clears verification until an administrator checks it again. Employee/customer order payloads never include employee addresses, emergency contacts, licence numbers or document links; customer delivery contacts contain only name, phone and ID. Cloudinary access-control reference: https://cloudinary.com/documentation/control_access_to_media .

An employee sees only current assignments and their completed history, can pick up a packed order, mark it on the way, record an unsuccessful attempt/retry and complete it after collecting the exact COD amount. Employees cannot pack, cancel, reassign, change prices, create staff or access another employee's orders. Reassignment and permissions are checked again inside the order transaction. Cash collection stores both the employee and the user who recorded it.

Collected cash remains in the employee's **My cash** balance until an administrator physically receives it. In the employee editor, open **Manage cash handovers**, choose the delivered orders, enter the exact amount counted and confirm receipt. A separate immutable handover receipt records employee, covered orders, total, timestamp and receiving administrator. Retry keys and order locks prevent double receipt. Employees can view their balance/receipts but cannot acknowledge their own cash handover. Active orders must be reassigned and outstanding cash received before deactivation. Historical cash entries without a recorded collection employee are left untouched; they are not automatically assigned or settled.

## Configure product photos

Use the exact **Cloud name** from Cloudinary, along with its API key and secret. The account/API-key display name is not necessarily the cloud name. The verified cloud name is `kbs5o32p`. Account authentication succeeds, but the supplied API key currently denies the `create` action. Enable upload/create permissions for this key, or replace it with an upload-enabled key from the same cloud, before uploading product photos.

Admins can publish real products without photos meanwhile. Uploaded JPEG/PNG/WebP files are validated and sent from the authenticated backend to Cloudinary. Private Cloudinary credentials never enter the mobile bundle. A missing photo shows a neutral placeholder, not an unrelated sample product image.

## Run or build the mobile app

```powershell
flutter pub get
flutter run --dart-define-from-file=config/mobile.production.json
flutter build apk --debug --dart-define-from-file=config/mobile.production.json
```

Deploy backend API version 5 before using the new app against Render. `GET /api/health/` must return `api_version: 5`. Run migrations through `start.sh`, including migration 0008 for list indexes. Until deployment, endpoint errors are displayed with retry controls; the app never fills the store with fabricated products.

Catalog, wishlist, customer/admin orders, delivery assignments/history, employee selection and cash lists use cursor pagination with 24 rows per request (maximum 48). Search, category, status and employee eligibility filters run on the backend across the whole matching collection. The app loads more near the end, supports pull-to-refresh, preserves existing rows on page errors, and stops fetching at the end or on invalid/repeated cursors. New collection clients send `paginate=true`; legacy internal clients retain their existing response shape.

Initial lists, details, account/cart restoration, summaries and network images display skeleton placeholders. Reduced-motion settings disable skeleton animation. Saved carts refresh only their saved product IDs in bounded batches. Employee feeds and receipt history remain scoped to the signed-in employee; a fresh employee login validates the new session before showing cached summaries. Temporary verification files are removed after checks.

Public catalog pages and config use an in-memory cache lasting 20 seconds, capped at 32 entries. Pull-to-refresh bypasses it; successful writes invalidate it, including older requests still in flight. Cached objects are copied before returning. Personal data, orders, stock reconciliation by saved IDs, cash and authenticated staff responses are never added to this cache. Checkout still validates prices and stock on the server.

All API request handlers, including delivery employee access, document access and cash receipts, live in `views.py`. Employee and cash validation lives in `serializers.py`. Shared order/stock/cash rules stay in `commerce.py`, Cloudinary integration in `gateways.py`, cursor handling in `views.py`, and shared error handling in `errors.py`. Models and URL routing keep their separate Django responsibilities. Splitting these modules does not add network requests or database queries.

Tamil product names are required; English names are optional. Tamil-only products use their Tamil name in the catalog, cart, wishlist and order/delivery labels, while stored English values remain empty. Product and wishlist cursors sort by Tamil name and ID, backed by the index in migration 0009. Omitting an English name therefore does not put every product at the same empty cursor position. Older order snapshots retain their original stored names.

Typing an English grocery name in the admin product form requests a Tamil suggestion after a short pause. The staff-only `/api/admin/products/tamil-name/` endpoint uses a curated grocery vocabulary and understands common pack sizes such as `Toor Dal 1 kg`. It does not seed products, contact unofficial translation services or require a paid API key. Unfamiliar names need manual Tamil entry. Suggestions remain editable, manual edits are preserved, stale requests are ignored, and failed requests end with a manual-entry option.

The storefront uses only published catalog records and actual cart totals; it never inserts sample cards, sales counters or fictitious discounts. Product photos use the admin-uploaded image, with a neutral placeholder when none exists. The bundled [Noto Sans Tamil font](https://github.com/google/fonts/tree/main/ofl/notosanstamil) provides Tamil glyphs across platforms; its SIL Open Font License is included in `assets/fonts/OFL.txt` and the app license registry.

The admin Employees tab and saved employee form offer View employee portal. This opens the real delivery sign-in with the employee ID filled in; a staff password is still required before any assigned orders or cash appear. `/employee` opens the same authenticated portal. Return to admin clears the delivery session; admin access still requires the existing admin session or an admin sign-in. Local role selection is navigation only, never API authorization.

Credential incident: historical commits contain `backend/.env`. The current tracked tree excludes `.env` and `backend/render.env`, but deleting files does not revoke leaked credentials. Reset the exposed Neon role password, update `DATABASE_URL` in the ignored local environment files and Render, then redeploy. Review Neon access/activity and revoke any other exposed credentials. Do not restore `.env` from Git history. See [Neon role passwords](https://neon.com/docs/manage/roles) and [GitHub sensitive-data remediation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository). History rewriting and force-pushing require coordination with collaborators; rotating the credential is the first step.

`config/mobile.production.json` contains only the public API URL. Never put database credentials, payment secrets or Cloudinary secrets in Dart defines or Flutter assets. Cash-on-delivery checkout is used on every supported platform.

Customers browse products without signing in. Adding to cart, saving to a wishlist and checking out require a customer account. With `CUSTOMER_OTP_ENABLED=false`, entering an Indian mobile number displays a random 5-digit demo code on the same screen. The customer must type it to sign in; codes expire after five minutes, allow five attempts and can be used once. This is temporary test verification, not SMS verification or proof of phone ownership: anyone with a number can access its demo account. Replace it with verified SMS OTP before public use. Setting the flag to true currently blocks demo sign-in until an SMS provider is implemented.

Each number owns its saved address, wishlist and order history in the database. Signing in again restores that account; another number has separate data. Customer sessions stay in encrypted device storage until logout/change number, which also clears the device cart. Addresses can be edited under Account and are filled at checkout. Staff sessions remain in memory and require sign-in on a cold start. Keep `backend/build.sh` and `backend/start.sh`: Render uses them to build the service and apply database migrations on deployment.

The customer sees their assigned contact, optional arrival estimate, cash due/receipt and order timeline, refreshed every 15 seconds. Orders and inventory history are retained when a product is removed. Storefront promotional images are generated editorial assets; catalog photos continue to come from real admin uploads. See `assets/images/prompts.txt` for the image prompts and provenance.

## Verify runtime configuration

```powershell
.\.venv\Scripts\python.exe backend/manage.py check
flutter analyze
flutter build apk --debug --dart-define-from-file=config/mobile.production.json
```

Test-only files and the obsolete prototype wrappers were removed after verification. Routes now open the store and admin screens directly.

Before a public release, configure Android release signing; the repository's existing release configuration still uses the development signing key. Credentials previously committed in `.env` remain in Git history and must be rotated before production use.
