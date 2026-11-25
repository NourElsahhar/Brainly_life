// Entry point of Baseet's Cloud Functions (owner: M1).
// Every exported function is deployed:
//   aiGateway      -> callable, the only way the app talks to the AI
//   deleteUserData -> trigger, cleans everything when an account is deleted
//
// See functions/README.md.

import {initializeApp} from "firebase-admin/app";

initializeApp();

export {aiGateway} from "./ai/aiGateway";
export {deleteUserData} from "./account/deleteUserData";
