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

`render.yaml` documents equivalent settings for a new service. Do not create a duplicate service just to update the existing one. The local `.env` is deliberately excluded from Git and will not automatically reach Render. The ignored `backend/render.env` file contains all current deployment values in a single copy-paste block; use Render **Environment > Add from .env** to import its complete contents. Startup only checks for pending migrations and creates the first administrator. Apply database migrations manually before deployment. No demo data is seeded.

The additive migrations leave existing prototype records in the database but unpublished/inactive. Customer APIs only expose published products and the signed-in customer's own orders. Publish new real products from the admin app. Demo seeding has been removed. Existing real legacy catalog records should be reviewed before republishing them through Django administration.

## Cash on delivery and order operations

New orders use cash on delivery only. There is no payment gateway, online payment SDK, or payment webhook. Remove old `RAZORPAY_*` and `PAYMENT_GATEWAY_ENABLED` variables from the Render environment; the application no longer reads them. The local `.env` and `render.env` have already been updated. Historical online payment reference columns remain in the database to preserve existing records.

Customers sign in, review their saved address and place an order without prepaying. The server calculates prices and delivery charges, reserves stock atomically, and uses an idempotency key to prevent duplicate orders on retries. Customers may cancel a new order before preparation begins; cancellation restores stock exactly once.

Administrators manage **New -> Preparing -> Packed -> Out for Delivery -> Delivered**. Dispatch requires an active delivery person. At delivery, the assigned employee enters the exact cash amount and confirms receipt from the customer; an administrator can also record this on the employee's behalf. Only then does the order become Delivered / Cash collected. The receipt records the amount, timestamp and staff user. The dashboard separately reports cash collected and cash still due; placing an order does not count as cash received.

An unsuccessful delivery becomes **Delivery Attempted** with a mandatory customer-visible reason. Staff can assign another person/arrival estimate and retry, or cancel after confirming the items have returned to store. Orders already out for delivery must first be marked attempted before cancellation; this prevents restoring stock that is still with a driver. Delivered orders cannot be cancelled or edited through this flow. Delivery notes, assigned contact, estimated arrival and the activity timeline appear in the customer app. Administrators manage preparation, assignments, cancellations and cash handovers. Delivery employees sign in separately to manage only their assigned work. Active deliveries support permission-based device GPS sharing, recorded trip display and Google Maps navigation; see the delivery workspace notes below.

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

Deploy backend API version 5 before using the new app against Render. `GET /api/health/` must return `api_version: 5`. Apply pending migrations manually with `python manage.py migrate` before deployment. `start.sh` only checks for unapplied migrations and stops if any remain; it never applies them. Use `bash build.sh` as the Render build command and remove any dashboard build command that runs `migrate`. Until deployment, endpoint errors are displayed with retry controls; the app never fills the store with fabricated products.

Catalog, wishlist, customer/admin orders, delivery assignments/history, employee selection and cash lists use cursor pagination with 24 rows per request (maximum 48). Search, category, status and employee eligibility filters run on the backend across the whole matching collection. The app loads more near the end, supports pull-to-refresh, preserves existing rows on page errors, and stops fetching at the end or on invalid/repeated cursors. New collection clients send `paginate=true`; legacy internal clients retain their existing response shape.

Initial lists, details, account/cart restoration, summaries and network images display skeleton placeholders. Reduced-motion settings disable skeleton animation. Saved carts refresh only their saved product IDs in bounded batches. Employee feeds and receipt history remain scoped to the signed-in employee; a fresh employee login validates the new session before showing cached summaries. Temporary verification files are removed after checks.

Public catalog pages and config use an in-memory cache lasting 20 seconds, capped at 32 entries. Pull-to-refresh bypasses it; successful writes invalidate it, including older requests still in flight. Cached objects are copied before returning. Personal data, orders, stock reconciliation by saved IDs, cash and authenticated staff responses are never added to this cache. Checkout still validates prices and stock on the server.

All API request handlers, including delivery employee access, document access and cash receipts, live in `views.py`. Employee and cash validation lives in `serializers.py`. Shared order/stock/cash rules stay in `commerce.py`, Cloudinary integration in `gateways.py`, cursor handling in `views.py`, and shared error handling in `errors.py`. Models and URL routing keep their separate Django responsibilities. Splitting these modules does not add network requests or database queries.

Tamil product names are required; English names are optional. Tamil-only products use their Tamil name in the catalog, cart, wishlist and order/delivery labels, while stored English values remain empty. Product and wishlist cursors sort by Tamil name and ID, backed by the index in migration 0009. Omitting an English name therefore does not put every product at the same empty cursor position. Older order snapshots retain their original stored names.

Typing an English grocery name in the admin product form requests a Tamil suggestion after a short pause. The staff-only `/api/admin/products/tamil-name/` endpoint uses a curated grocery vocabulary and understands common pack sizes such as `Toor Dal 1 kg`. It does not seed products, contact unofficial translation services or require a paid API key. Unfamiliar names need manual Tamil entry. Suggestions remain editable, manual edits are preserved, stale requests are ignored, and failed requests end with a manual-entry option.

The storefront uses only published catalog records and actual cart totals; it never inserts sample cards, sales counters or fictitious discounts. Product photos use the admin-uploaded image, with a neutral placeholder when none exists. The bundled [Noto Sans Tamil font](https://github.com/google/fonts/tree/main/ofl/notosanstamil) provides Tamil glyphs across platforms; its SIL Open Font License is included in `assets/fonts/OFL.txt` and the app license registry.

Admin and delivery workspaces stay open after saves, refreshes and Android back presses. Staff tokens and the last authenticated workspace are saved in platform secure storage so reopening the app returns to that workspace. Expired credentials show the same staff sign-in screen; only explicit logout leaves the workspace. Creating or editing an employee never switches roles automatically. The admin Employees tab and saved employee form offer an explicit View employee portal action. This opens the real delivery sign-in with the employee ID filled in. `/employee` opens the same authenticated portal. Return to admin clears the delivery session and restores the admin workspace; admin access still requires an admin token. Local role selection is navigation only, never API authorization.

New employee IDs use `BB` + current server year + a sequence padded to at least three digits, for example `BB2026001`, `BB2026002`. Migration 0010 adds the per-year counter, locked in the employee creation transaction. Deletions do not reuse IDs, failed creations roll back the allocation, and existing employee IDs remain valid. Keep this migration file for Render deployment.

Delivery employees sign in with their employee ID **or** registered Indian mobile number, plus their password. Passwords are required when admins create employees or complete older accounts without a usable password. Employee IDs remain in the `BB2026001` format. The previous phone-only test login and its environment switch are removed; even a stale Render variable cannot enable that bypass. Migration 0011 revokes previous delivery tokens so each employee signs in again with a password. Admin/customer sessions are unaffected. Admins must set a password for older employees created in phone-only mode. Country-code normalization, active-account checks, login throttling and employee-only access still apply. Phone or password changes revoke the employee's sessions.

Credential incident: historical commits contain `backend/.env`. The current tracked tree excludes `.env` and `backend/render.env`, but deleting files does not revoke leaked credentials. Reset the exposed Neon role password, update `DATABASE_URL` in the ignored local environment files and Render, then redeploy. Review Neon access/activity and revoke any other exposed credentials. Do not restore `.env` from Git history. See [Neon role passwords](https://neon.com/docs/manage/roles) and [GitHub sensitive-data remediation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository). History rewriting and force-pushing require coordination with collaborators; rotating the credential is the first step.

`config/mobile.production.json` contains only the public API URL. Never put database credentials, payment secrets or Cloudinary secrets in Dart defines or Flutter assets. Cash-on-delivery checkout is used on every supported platform.

Customers browse products without signing in. Adding to cart, saving to a wishlist and checking out require a customer account. With `CUSTOMER_OTP_ENABLED=false`, entering an Indian mobile number displays a random 5-digit demo code on the same screen. The customer must type it to sign in; codes expire after five minutes, allow five attempts and can be used once. This is temporary test verification, not SMS verification or proof of phone ownership: anyone with a number can access its demo account. Replace it with verified SMS OTP before public use. Setting the flag to true currently blocks demo sign-in until an SMS provider is implemented.

Each number owns its saved address, wishlist and order history in the database. Signing in again restores that account; another number has separate data. Customer sessions stay in encrypted device storage until logout/change number, which also clears the device cart. Addresses can be edited under Account and are filled at checkout. Staff tokens and the active staff workspace are restored from platform secure storage on a cold start. Keep `backend/build.sh` and `backend/start.sh`: Render uses them to build the service and check migration readiness. Database migrations are applied manually by the operator.

The customer sees their assigned contact, optional arrival estimate, cash due/receipt and order timeline, refreshed every 15 seconds. Orders and inventory history are retained when a product is removed. Storefront promotional images are generated editorial assets; catalog photos continue to come from real admin uploads. See `assets/images/prompts.txt` for the image prompts and provenance.

## Verify runtime configuration

The product editor suggests Tamil names for supported English grocery names and
common Tanglish spellings, such as `Rice` / `Arisi` → `அரிசி`, `Ponni Arisi` →
`பொன்னி அரிசி`, and `Sakkarai` → `சர்க்கரை`. Quantities such as `Arisi 1kg`
are supported. Review suggestions before publishing; unfamiliar names still need
manual Tamil entry. Suggestions never overwrite a manually edited Tamil name
unless **Suggest Tamil** is tapped.

If product photo uploads report missing **create/upload permission**, the
Cloudinary key authenticates but cannot create assets. An account administrator
must grant the backend key permission to upload/create assets in the correct
product environment, or supply a suitable replacement key. Configure matching
`CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY` and `CLOUDINARY_API_SECRET` in the
ignored local environment and Render environment, then restart/redeploy the
backend. Retrying or changing a valid image cannot fix a provider permission
denial. Never add API secrets to the Flutter app or tracked files.

```powershell
.\.venv\Scripts\python.exe backend/manage.py check
flutter analyze
flutter build apk --debug --dart-define-from-file=config/mobile.production.json
```

Test-only files and the obsolete prototype wrappers were removed after verification. Routes now open the store and admin screens directly.

Before a public release, configure Android release signing; the repository's existing release configuration still uses the development signing key. Credentials previously committed in `.env` remain in Git history and must be rotated before production use.


## Live catalog search and browse

The existing Antigravity green/cream screens use the public `/api/catalog/browse/` facets endpoint for category/brand names, counts, image URLs and supported collections. Facet photos come from existing admin-uploaded ProductImage records. Empty categories and unsupported merchandising sections are never invented. Category tiles, the browse rail and brand tiles request matching backend products; search uses 350 ms debounce, ignores stale replies, supports Tamil/English names, category, brand, description and SKU, and combines filters before cursor pagination. Product details, customer-login-gated cart/wishlist actions, retry controls and skeleton loading remain available.

`/api/products/` accepts `search`, `category`, `brand`, `min_price`, `max_price`, `in_stock=true`, `ordering=price|-price|name`, and `collection=best_sellers|most_bought|under_100`. Prices must be finite/non-negative and min must not exceed max. Best Sellers ranks units from delivered, paid/cash-collected orders belonging to customers. Most Bought ranks distinct completed orders. Pending, cancelled and uncollected orders do not contribute. Under 100 is a strict price filter. Collections appear only when matching published grocery products exist. The current schema has no product creation timestamp, configured MRP/discount schedule or value-pack flag exposed by admin, so New Arrivals, Today's Deals and Value Packs remain hidden. UUID order and price order are never substituted for sales or arrival dates.

Fresh produce categories are excluded from customer catalog, details, wishlist and checkout; existing records and order history are retained. New/changed fresh produce categories are rejected by product validation. Grocery categories such as dried fruits and vegetable oils remain allowed. Product photos require an admin-uploaded image record; unverified legacy URLs are not displayed. Missing photos use neutral basket/category icons. MRP is not synthesized, savings/discounts are not fabricated, and cart totals use the exact backend delivery fee without a hardcoded free-delivery threshold. Login stays in the hamburger menu and existing purchase authentication remains unchanged.

This search/browse completion adds no database migrations and seeds no records. The existing delivery-password migration 0011 is a separate pending change; run it manually if not already applied. No migrations are applied by application startup.


## Delivery workspace and customer confirmation

The admin queue opens on Active orders. Search by order ID, customer, mobile,
address or employee; combine stage, Needs employee and Today filters. Stage
counts come from the server and pages contain at most 48 orders (24 by default).
Short order references keep cards readable; full references remain in details.
Cancelled cards show the reason and no cash due, without duplicate status chips.
A 1,006-order isolated test verifies filtering and cursor paging; this is a
functional check, not a production traffic benchmark.

Employee onboarding has three stages: Login, Work details, Verify and activate.
Existing checks still require active accounts, original-document verification and
valid licences for motor vehicles. Only eligible employees appear in assignment.
Choosing an employee saves the assignment immediately. Select packed orders in
the queue to assign up to 50 at once. Batch assignment validates and locks every
selected order; if one is no longer packed, none of that batch is assigned.
Normal store work is
Prepare -> Pack -> Assign; the employee picks up from their own app. Admin pickup
and completion controls live under Admin delivery assistance for exceptional use.
When an administrator personally receives the customer cash, the completion dialog
has an explicit cash-already-with-store option. This credits the store directly
and does not leave a false debt against the assigned employee.

Dispatch issues a five-digit code for that order. Only its authenticated customer
can retrieve it from their order detail endpoint. It is never included in staff
or shared order serializers. The code expires after two hours; five incorrect
attempts lock it, and only the customer can request a fresh code (five refresh
requests per hour per order). Incorrect attempts persist without recording cash.
Completion requires the code plus the exact COD amount and explicit cash receipt
confirmation, including when an administrator assists. Repeating a successful
cash completion does not create another receipt. Historical prepaid orders use
code verification without collecting cash again. The existing customer demo
login is still not proof of phone ownership: configure verified SMS login before
public release; delivery confirmation cannot secure a compromised customer account.

An employee can enable trip location sharing after pickup and stop it explicitly.
Only active, assigned, verified employees can submit fresh coordinates for their
orders. Android uses a visible foreground-service notification; iOS and web need
the app open. App termination, permission denial, battery restrictions, lost GPS
or network access can interrupt updates. Reopen the active delivery and resume
sharing after an app restart. No always-on or off-duty tracking is implemented.
Customer maps disappear after delivery/cancellation. Staff can review recorded
fixes; timestamps and accuracy distinguish recent fixes from stale information.
The displayed line joins sampled GPS fixes and is not a calculated road route.
Google Maps navigation uses the customer's address; verify that Maps resolves the
address correctly. No destination coordinates or road ETA are fabricated.

Embedded maps use flutter_map with OpenStreetMap attribution. MAP_TILE_URL can
select a compatible tile provider via a Dart define. The default public tile
service is suitable for development; configure a provider appropriate for your
production volume and preserve its attribution and usage requirements.
Location storage is bounded to approximately 1,000 fixes per order and responses
to at most 300 sampled fixes. Schedule the following command daily to remove
closed-trip fixes older than seven days:

```powershell
.\.venv\Scripts\python.exe backend/manage.py purge_delivery_locations --dry-run
.\.venv\Scripts\python.exe backend/manage.py purge_delivery_locations
```

Deploy the backend and mobile update together. Apply migration 0012 manually
before serving the new backend; application startup does not run migrations.
Existing out-for-delivery orders obtain a code when their customer taps Get a
fresh delivery code. Upgrade employee clients before enabling code-required
completion. Real-phone pickup, Google Maps handoff, background behaviour,
customer code entry and cash handover must be acceptance-tested before release.


## Mobile operations dashboard

The admin workspace uses Dashboard, Orders, Products, Delivery and More navigation.
Dashboard summaries come from the authenticated `/api/admin/dashboard/` snapshot;
there are no seeded dashboard records, synthetic charts or generated catalog photos.
The header's Live data indicator reflects a successful API refresh, not store
opening hours or employee presence. A bell badge counts real attention categories.

Today's queue counts are current stages for orders placed on the store's local
calendar day. Delivered counts deliveries completed that day, including orders
placed earlier. The pipeline and COD balances are totals across recorded orders.
Assigned is a display/filter for packed orders with an employee, not a new stored
order status. Pipeline checkpoints are not additive: cash-received orders are also
delivered. Late deliveries are flagged only when a recorded arrival estimate has
passed. No route time or ETA is invented.

Cash held by employees, confirmed handovers and direct admin receipts remain
separate. Handovers are summed from receipt records once, not once per attached
order. Unallocated collected cash is flagged for reconciliation. The current cash
flow does not record employee-submitted amounts or an offline/online presence
signal; those values are labelled as not recorded. Verification still requires
counting physical cash and confirming the exact selected order total.

Attention cards and pipeline steps open filtered queues. Order cards offer direct
preparation, packing and assignment actions. Employee pickup and code/COD checks
remain in the existing delivery flow. More includes real category/brand filters,
recorded product requests, on-demand delivery configuration and recorded-total
reports. Store settings are read-only; no unsupported settings writes are implied.

Products show Tamil names first and expose Edit, Stock and Hide/Publish actions.
Hidden grocery records can be managed and republished by administrators while
remaining absent from customer browse, details and checkout. Product images still
come exclusively from admin uploads. Employee creation retains the three-step
wizard with a compact introduction and a review before activation.

This update extends existing API responses and uses existing schema fields; it
adds no database migration beyond the earlier delivery migration 0012. Deploy
the matching backend before using the new app. Isolated checks cover empty data,
correct reporting periods, cash accounting, publication, permissions, derived
filters and bounded previews with 1,005 orders. Phone layouts are checked at
360 and 320 logical pixels, including larger text. Preview images are rendered
from an empty isolated database and do not represent live store balances.

### Admin presentation rebuild

The admin workspace now shares `lib/store/admin_design_system.dart`: a compact
mint/cream palette, semantic badges, bundled Tamil typography, lightweight card
surfaces and a floating five-destination navigation dock. Existing dashboard,
product catalogue/editor, order queues/details, delivery control/team, employee
onboarding/picker, cash accounts/receipts, reports, requests and More tools use
this presentation. Product images retain their backend URLs and use contain fit.
The employee picker opens as a searchable sheet. Product save and cash receipt
actions stay visible outside the scrollable content.

More uses tool tiles instead of grouped menu rows. Categories and brands continue
to browse existing product text facets. Store settings remain read-only and the
unused delivery-slots entry is omitted. Charts show existing aggregate counts
and cash reconciliation; no sales time series, trends or sample records are added.
Recorded sales are labelled all-time, matching the current dashboard API.

This rebuild changes Flutter presentation only, with no API/schema/migration
changes. Authentication, pagination, product payloads, stock validation,
translation suggestions, order transitions, verification codes and exact cash
reconciliation still use the existing services and handlers. Migration and Git
push remain manual.

Validation: Flutter analysis and six temporary widget checks covering the admin
shell/navigation, actual public product values/images, stock/publication callback
payloads, editor payload preservation, delivered/cancelled filters, required-field
validation, and empty/error layouts at 320/360/412 logical pixels. Temporary tests
and their temporary dependency are removed after checking. Previews under
`artifacts/admin-saas/` use existing public catalogue data or explicitly empty
private-data states; they do not show actual admin balances or private records.
Private backend review was declined, so live login, order mutation, assignment
and cash handover were not exercised against real accounts. Verify those flows
with an authorized admin/employee session before release.

Admin workflow refinement: Products, Orders, Delivery and Cash reuse the supplied
dashboard artwork in compact decorative headers. Order and delivery cards show
actual backend item thumbnails. Closed order views omit active-stage controls;
batch selection is opt-in and opens the packed queue. Required product fields
remain visible, while brand/SKU/description and arrival/message editing are
expandable. Preparation/packing uses one fixed bottom action; delivery completion
remains under admin assistance with the existing verification requirements.
Three additional temporary widget checks cover filtering, selection mode,
required-field validation, full-width headers and 320/360/412-pixel layouts with
normal and larger text. Private-data previews use explicit empty states only.
