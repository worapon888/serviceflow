package com.serviceflow.entity;

public enum Role {
    ADMIN,
    DISPATCHER,
    TECHNICIAN;

    public String getAuthority() {
        return "ROLE_" + this.name();
    }
}
