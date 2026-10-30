# Agaram Supermarket

Flutter customer and store administration app backed by Django REST Framework, Neon PostgreSQL, Razorpay and Cloudinary.

The app opens the customer store. **Login** opens staff sign-in. Admins publish the same products customers browse; all ordering, prices, stock, payments and delivery progress come from the API. There is no runtime sample catalog, sample cart, fake order history, fake reviews, or screen-jump access to administration.

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
- Environment: copy the backend values from your local `.env` into Render's Environment settings, including the Neon `DATABASE_URL`, a long random `SECRET_KEY`, admin credentials, and Razorpay/Cloudinary credentials. `DEBUG=false`.

`render.yaml` documents equivalent settings for a new service. Do not create a duplicate service just to update the existing one. The local `.env` is deliberately excluded from Git and will not automatically reach Render. The ignored `backend/render.env` file contains all current deployment values in a single copy-paste block; use Render **Environment > Add from .env** to import its complete contents. Startup applies migrations and creates the first administrator. No demo data is seeded.

The additive migrations leave existing prototype records in the database but unpublished/inactive. Customer APIs only expose published products and the signed-in customer's own orders. Publish new real products from the admin app. Demo seeding has been removed. Existing real legacy catalog records should be reviewed before republishing them through Django administration.

## Configure payments

Keep `PAYMENT_GATEWAY_ENABLED=true` and your Razorpay **test** keys in the backend environment for testing. Flutter receives only the public key and an order created by the server. It never receives the secret key.

In the Razorpay dashboard, configure a webhook pointing to:

`https://super-market-33m1.onrender.com/api/payments/razorpay/webhook/`

Subscribe to `payment.captured` and `order.paid`, and set its signing secret to the backend `RAZORPAY_WEBHOOK_SECRET`. Test and live webhook configurations are separate. Enable automatic capture, or let the server capture an authorised payment during verification. Fulfillment stays blocked until capture is verified. A client checkout callback alone never marks an order paid.

The server validates the signature, gateway order ID, amount, INR currency and capture status. Requests use an idempotency key and server-side product prices. Online checkout reserves stock for 30 minutes; unpaid checkouts can be cancelled from My orders. Expired reservations are released during subsequent checkout requests. For timely release when checkout traffic is low, schedule `python manage.py expire_checkouts` every five minutes using an existing job runner. Late captured payments after cancellation are flagged for manual fulfillment/refund review instead of being silently shipped or lost.

## Configure product photos

Use the exact **Cloud name** from Cloudinary, along with its API key and secret. The account/API-key display name is not necessarily the cloud name. The verified cloud name is `kbs5o32p`. Account authentication succeeds, but the supplied API key currently denies the `create` action. Enable upload/create permissions for this key, or replace it with an upload-enabled key from the same cloud, before uploading product photos.

Admins can publish real products without photos meanwhile. Uploaded JPEG/PNG/WebP files are validated and sent from the authenticated backend to Cloudinary. Private Cloudinary credentials never enter the mobile bundle. A missing photo shows a neutral placeholder, not an unrelated sample product image.

## Run or build the mobile app

```powershell
flutter pub get
flutter run --dart-define-from-file=config/mobile.production.json
flutter build apk --debug --dart-define-from-file=config/mobile.production.json
```

Deploy the backend API version 2 before using the new app against Render. `GET /api/health/` must return `api_version: 2`. Until deployment, endpoint errors are displayed with retry controls; the app never fills the store with fabricated products.

`config/mobile.production.json` contains only the public API URL. Never put database credentials, payment secrets or Cloudinary secrets in Dart defines or Flutter assets. Android/iOS support Razorpay checkout; desktop/web shoppers can use cash on delivery.

Customers browse products without signing in. Adding to cart, saving to a wishlist and checking out require a customer account. With `CUSTOMER_OTP_ENABLED=false`, entering an Indian mobile number displays a random 5-digit demo code on the same screen. The customer must type it to sign in; codes expire after five minutes, allow five attempts and can be used once. This is temporary test verification, not SMS verification or proof of phone ownership: anyone with a number can access its demo account. Replace it with verified SMS OTP before public use. Setting the flag to true currently blocks demo sign-in until an SMS provider is implemented.

Each number owns its saved address, wishlist and order history in the database. Signing in again restores that account; another number has separate data. Customer sessions stay in encrypted device storage until logout/change number, which also clears the device cart. Addresses can be edited under Account and are filled at checkout. Staff sessions remain in memory and require sign-in on a cold start. Keep `backend/build.sh` and `backend/start.sh`: Render uses them to build the service and apply database migrations on deployment.

Delivery is managed by real staff updates: **New -> Preparing -> Packed -> Out for Delivery -> Delivered**. Dispatch requires an active delivery person. The customer sees their assigned contact, optional arrival estimate, delivery note and order timeline, refreshed every 15 seconds. This is operational status tracking, not GPS live-location tracking. Orders and inventory are retained when a product is removed.

## Verify runtime configuration

```powershell
.\.venv\Scripts\python.exe backend/manage.py check
flutter analyze
flutter build apk --debug --dart-define-from-file=config/mobile.production.json
```

Test-only files and the obsolete prototype wrappers were removed after verification. Routes now open the store and admin screens directly.

Before a public release, configure Android release signing; the repository's existing release configuration still uses the development signing key. Credentials previously committed in `.env` remain in Git history and must be rotated before production use.
