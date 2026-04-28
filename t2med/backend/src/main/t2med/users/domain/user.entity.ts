export class User {
  uid: string;
  name: string;
  lastName: string;
  email: string;
  phone: string;
  emergencyPhone?: string | null;
  fcmToken?: string | null;
  createdAt?: any;
  updatedAt?: any;
}