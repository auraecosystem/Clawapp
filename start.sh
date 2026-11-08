git clone https://github.com/qingchencloud/clawapp.git
cd clawapp && npm run install:all && npm run build:h5
cp server/.env.example server/.env  # edit tokens
npm start
